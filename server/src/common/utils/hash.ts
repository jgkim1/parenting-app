import bcrypt from "bcrypt";
import { createHash } from "crypto";

const SALT_ROUNDS = 12;

export function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, SALT_ROUNDS);
}

export function comparePassword(plain: string, hash: string): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}

// 리프레시 토큰은 자체 엔트로피가 충분한 JWT이므로, bcrypt 대신 빠른 sha256으로
// 해시하여 DB에 저장한다 (탈취되어도 원문 토큰 없이는 재사용 불가).
export function hashToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}
