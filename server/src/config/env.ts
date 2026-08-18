import "dotenv/config";
import { z } from "zod";

// 서버 시작 시 필수 환경 변수를 검증하여, 설정 누락을 런타임 초기에 발견한다.
const envSchema = z.object({
  DATABASE_URL: z.string().min(1),
  PORT: z.coerce.number().default(4000),
  JWT_ACCESS_SECRET: z.string().min(1),
  JWT_REFRESH_SECRET: z.string().min(1),
  JWT_ACCESS_EXPIRES_IN: z.string().default("15m"),
  JWT_REFRESH_EXPIRES_IN: z.string().default("14d"),
  // 소셜 로그인은 선택 기능이라, 값이 없으면 해당 프로바이더 로그인 요청만 막고
  // 서버 자체는 정상 기동한다 (auth.service.ts에서 미설정 여부를 확인함).
  // 카카오는 클라이언트가 이미 발급받은 사용자 액세스 토큰을 그대로 검증하는 방식이라
  // 서버에 별도 키가 필요 없다. 구글은 ID 토큰의 발급 대상(aud)을 확인해야 해서 필요하다.
  GOOGLE_CLIENT_ID: z.string().optional(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error("환경 변수 검증에 실패했습니다:", parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
