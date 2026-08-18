import request from "supertest";
import { app } from "../src/app";
import { prisma } from "../src/config/prisma";

export const api = request(app);

// 각 테스트 시작 전에 호출해 이전 테스트의 데이터가 남지 않도록 전체 테이블을 비운다.
// 테이블 목록을 매번 조회해서 truncate하므로 스키마가 바뀌어도 별도 수정이 필요 없다.
export async function resetDatabase() {
  const tables = await prisma.$queryRaw<Array<{ tablename: string }>>`
    SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename != '_prisma_migrations';
  `;
  const tableNames = tables.map((t) => `"${t.tablename}"`).join(", ");
  if (tableNames.length > 0) {
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE ${tableNames} RESTART IDENTITY CASCADE;`);
  }
}

interface SignedUpUser {
  accessToken: string;
  refreshToken: string;
  userId: string;
  email: string;
  password: string;
}

let counter = 0;

// 매번 고유한 이메일로 회원가입하고 로그인 토큰까지 받아온다. role을 SELLER/ADMIN으로
// 올려야 하는 테스트는 반환된 userId로 직접 DB의 role을 갱신해서 쓴다.
export async function signUpUser(overrides?: Partial<{ email: string; password: string; nickname: string }>): Promise<SignedUpUser> {
  counter += 1;
  const email = overrides?.email ?? `user${counter}@example.com`;
  const password = overrides?.password ?? "password123";
  const nickname = overrides?.nickname ?? `테스터${counter}`;

  const res = await api.post("/api/auth/signup").send({ email, password, nickname });
  if (res.status !== 201) {
    throw new Error(`signUpUser 실패: ${res.status} ${JSON.stringify(res.body)}`);
  }

  return {
    accessToken: res.body.accessToken,
    refreshToken: res.body.refreshToken,
    userId: res.body.user.id,
    email,
    password,
  };
}

export async function setUserRole(userId: string, role: "CUSTOMER" | "SELLER" | "ADMIN") {
  await prisma.user.update({ where: { id: userId }, data: { role } });
}

export async function loginUser(email: string, password: string) {
  const res = await api.post("/api/auth/login").send({ email, password });
  if (res.status !== 200) {
    throw new Error(`loginUser 실패: ${res.status} ${JSON.stringify(res.body)}`);
  }
  return {
    accessToken: res.body.accessToken as string,
    refreshToken: res.body.refreshToken as string,
    userId: res.body.user.id as string,
  };
}

// JWT에는 발급 시점의 role이 그대로 박혀있으므로, DB에서 role을 올린 뒤에는
// 반드시 재로그인해서 새 토큰을 받아야 requireRole 검증을 통과할 수 있다.
export async function signUpWithRole(
  role: "SELLER" | "ADMIN",
  overrides?: Partial<{ email: string; password: string; nickname: string }>,
): Promise<SignedUpUser> {
  const user = await signUpUser(overrides);
  await setUserRole(user.userId, role);
  const { accessToken, refreshToken } = await loginUser(user.email, user.password);
  return { ...user, accessToken, refreshToken };
}

export function authHeader(accessToken: string) {
  return { Authorization: `Bearer ${accessToken}` };
}

// 카테고리/상품 생성 API는 없거나(카테고리) 판매자 권한이 필요해서(상품), 테스트
// 데이터 준비는 Prisma로 직접 만든다.
export async function createCategory(overrides?: Partial<{ name: string; slug: string }>) {
  counter += 1;
  return prisma.category.create({
    data: {
      name: overrides?.name ?? `테스트카테고리${counter}`,
      slug: overrides?.slug ?? `test-category-${counter}`,
    },
  });
}

export async function createArticleCategory(overrides?: Partial<{ name: string; slug: string }>) {
  counter += 1;
  return prisma.articleCategory.create({
    data: {
      name: overrides?.name ?? `테스트정보카테고리${counter}`,
      slug: overrides?.slug ?? `test-article-category-${counter}`,
    },
  });
}

export async function createProduct(
  sellerId: string,
  categoryId: string,
  overrides?: Partial<{ name: string; description: string; price: number; stock: number; isActive: boolean }>,
) {
  counter += 1;
  return prisma.product.create({
    data: {
      sellerId,
      categoryId,
      name: overrides?.name ?? `테스트상품${counter}`,
      description: overrides?.description ?? "테스트 상품 설명입니다.",
      price: overrides?.price ?? 10000,
      stock: overrides?.stock ?? 10,
      isActive: overrides?.isActive ?? true,
    },
  });
}
