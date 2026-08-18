import { z } from "zod";

export const signupSchema = z.object({
  email: z.string().email("올바른 이메일 형식이 아닙니다."),
  password: z.string().min(8, "비밀번호는 8자 이상이어야 합니다."),
  nickname: z.string().min(1, "닉네임을 입력해주세요.").max(30),
});
export type SignupInput = z.infer<typeof signupSchema>;

export const loginSchema = z.object({
  email: z.string().email("올바른 이메일 형식이 아닙니다."),
  password: z.string().min(1, "비밀번호를 입력해주세요."),
});
export type LoginInput = z.infer<typeof loginSchema>;

export const refreshSchema = z.object({
  refreshToken: z.string().min(1, "리프레시 토큰이 필요합니다."),
});
export type RefreshInput = z.infer<typeof refreshSchema>;

export const kakaoLoginSchema = z.object({
  accessToken: z.string().min(1, "카카오 액세스 토큰이 필요합니다."),
});
export type KakaoLoginInput = z.infer<typeof kakaoLoginSchema>;

export const googleLoginSchema = z.object({
  idToken: z.string().min(1, "구글 ID 토큰이 필요합니다."),
});
export type GoogleLoginInput = z.infer<typeof googleLoginSchema>;
