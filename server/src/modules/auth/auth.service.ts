import type { AuthProvider, User, UserRole } from "@prisma/client";
import { OAuth2Client } from "google-auth-library";
import { env } from "../../config/env";
import { prisma } from "../../config/prisma";
import {
  ConflictError,
  ServiceUnavailableError,
  UnauthorizedError,
} from "../../common/errors/AppError";
import { comparePassword, hashPassword, hashToken } from "../../common/utils/hash";
import {
  getTokenExpiry,
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
} from "../../common/utils/jwt";
import type { GoogleLoginInput, KakaoLoginInput, LoginInput, RefreshInput, SignupInput } from "./auth.schema";

function toSafeUser(user: User) {
  const { passwordHash, ...safeUser } = user;
  return safeUser;
}

async function issueTokenPair(userId: string, role: UserRole) {
  const accessToken = signAccessToken({ sub: userId, role });
  const refreshToken = signRefreshToken({ sub: userId, role });

  await prisma.refreshToken.create({
    data: {
      userId,
      tokenHash: hashToken(refreshToken),
      expiresAt: getTokenExpiry(refreshToken),
    },
  });

  return { accessToken, refreshToken };
}

export async function signup(input: SignupInput) {
  const existing = await prisma.user.findUnique({ where: { email: input.email } });
  if (existing) {
    throw new ConflictError("이미 가입된 이메일입니다.");
  }

  const passwordHash = await hashPassword(input.password);
  const user = await prisma.user.create({
    data: {
      email: input.email,
      passwordHash,
      nickname: input.nickname,
    },
  });

  const tokens = await issueTokenPair(user.id, user.role);
  return { user: toSafeUser(user), ...tokens };
}

export async function login(input: LoginInput) {
  const user = await prisma.user.findUnique({ where: { email: input.email } });
  // 소셜 로그인으로만 가입한 계정은 passwordHash가 없어 비밀번호 로그인이 애초에 불가능하다.
  const passwordMatches = user?.passwordHash
    ? await comparePassword(input.password, user.passwordHash)
    : false;

  if (!user || !passwordMatches) {
    // 이메일 존재 여부가 드러나지 않도록 동일한 메시지를 사용한다.
    throw new UnauthorizedError("이메일 또는 비밀번호가 올바르지 않습니다.");
  }

  const tokens = await issueTokenPair(user.id, user.role);
  return { user: toSafeUser(user), ...tokens };
}

export async function refresh(input: RefreshInput) {
  let payload;
  try {
    payload = verifyRefreshToken(input.refreshToken);
  } catch {
    throw new UnauthorizedError("리프레시 토큰이 유효하지 않거나 만료되었습니다.");
  }

  const tokenHash = hashToken(input.refreshToken);
  const stored = await prisma.refreshToken.findFirst({
    where: { userId: payload.sub, tokenHash, revoked: false },
  });

  if (!stored || stored.expiresAt < new Date()) {
    throw new UnauthorizedError("리프레시 토큰이 유효하지 않거나 만료되었습니다.");
  }

  // 재사용 공격을 막기 위해 사용한 리프레시 토큰은 즉시 무효화하고(rotate) 새로 발급한다.
  await prisma.refreshToken.update({
    where: { id: stored.id },
    data: { revoked: true },
  });

  return issueTokenPair(payload.sub, payload.role);
}

export async function logout(input: RefreshInput) {
  const tokenHash = hashToken(input.refreshToken);
  await prisma.refreshToken.updateMany({
    where: { tokenHash, revoked: false },
    data: { revoked: true },
  });
}

interface SocialProfile {
  provider: AuthProvider;
  providerId: string;
  email: string | null;
  nickname: string;
}

// 프로바이더별 프로필로 기존 계정을 찾거나 새로 만든다. 로그인/회원가입을 한 번에 처리하는
// 소셜 로그인의 특성상, 이미 이메일/비밀번호로 가입된 계정과 같은 이메일이 들어오면 계정을
// 몰래 합치지 않고 명시적으로 거부한다(계정 탈취 방지).
async function findOrCreateSocialUser(profile: SocialProfile) {
  let user = await prisma.user.findFirst({
    where: { provider: profile.provider, providerId: profile.providerId },
  });

  if (!user) {
    if (profile.email) {
      const existingByEmail = await prisma.user.findUnique({ where: { email: profile.email } });
      if (existingByEmail) {
        throw new ConflictError(
          existingByEmail.provider === "LOCAL"
            ? "이미 이메일/비밀번호로 가입된 이메일입니다. 해당 방식으로 로그인해주세요."
            : "이미 다른 방식으로 가입된 이메일입니다.",
        );
      }
    }

    user = await prisma.user.create({
      data: {
        // 카카오는 이메일 제공에 사용자 동의가 필요해 없을 수 있으므로, 없으면 계정 식별용
        // 더미 이메일을 만든다. 실제 알림/찾기 용도로는 쓰이지 않는다.
        email: profile.email ?? `${profile.provider.toLowerCase()}_${profile.providerId}@social.local`,
        nickname: profile.nickname,
        provider: profile.provider,
        providerId: profile.providerId,
        passwordHash: null,
      },
    });
  }

  const tokens = await issueTokenPair(user.id, user.role);
  return { user: toSafeUser(user), ...tokens };
}

interface KakaoUserMeResponse {
  id: number;
  kakao_account?: {
    email?: string;
    profile?: { nickname?: string };
  };
}

// 클라이언트(Flutter)가 카카오 SDK로 이미 로그인해서 받은 사용자 액세스 토큰을 그대로 받아
// 카카오 서버에 프로필을 조회하는 방식이라, 서버는 별도의 카카오 앱 키가 필요 없다.
export async function loginWithKakao(input: KakaoLoginInput) {
  const response = await fetch("https://kapi.kakao.com/v2/user/me", {
    headers: { Authorization: `Bearer ${input.accessToken}` },
  });

  if (!response.ok) {
    throw new UnauthorizedError("카카오 인증에 실패했습니다.");
  }

  const profile = (await response.json()) as KakaoUserMeResponse;
  return findOrCreateSocialUser({
    provider: "KAKAO",
    providerId: String(profile.id),
    email: profile.kakao_account?.email ?? null,
    nickname: profile.kakao_account?.profile?.nickname ?? `카카오사용자${profile.id}`,
  });
}

// 구글은 클라이언트가 받은 ID 토큰(JWT) 자체를 서명 검증하는 방식이라, 우리 앱의 클라이언트
// ID(발급 대상)를 서버가 알고 있어야 한다. 미설정 시 로그인 자체를 막는다.
export async function loginWithGoogle(input: GoogleLoginInput) {
  if (!env.GOOGLE_CLIENT_ID) {
    throw new ServiceUnavailableError("구글 로그인이 아직 설정되지 않았습니다.");
  }

  const client = new OAuth2Client(env.GOOGLE_CLIENT_ID);
  let payload;
  try {
    const ticket = await client.verifyIdToken({
      idToken: input.idToken,
      audience: env.GOOGLE_CLIENT_ID,
    });
    payload = ticket.getPayload();
  } catch {
    throw new UnauthorizedError("구글 인증에 실패했습니다.");
  }

  if (!payload) {
    throw new UnauthorizedError("구글 인증에 실패했습니다.");
  }

  return findOrCreateSocialUser({
    provider: "GOOGLE",
    providerId: payload.sub,
    email: payload.email ?? null,
    nickname: payload.name ?? `구글사용자${payload.sub.slice(0, 6)}`,
  });
}
