import type { Request, Response } from "express";
import * as authService from "./auth.service";

export async function signupHandler(req: Request, res: Response) {
  const result = await authService.signup(req.body);
  res.status(201).json(result);
}

export async function loginHandler(req: Request, res: Response) {
  const result = await authService.login(req.body);
  res.status(200).json(result);
}

export async function refreshHandler(req: Request, res: Response) {
  const result = await authService.refresh(req.body);
  res.status(200).json(result);
}

export async function logoutHandler(req: Request, res: Response) {
  await authService.logout(req.body);
  res.status(204).send();
}

export async function kakaoLoginHandler(req: Request, res: Response) {
  const result = await authService.loginWithKakao(req.body);
  res.status(200).json(result);
}

export async function googleLoginHandler(req: Request, res: Response) {
  const result = await authService.loginWithGoogle(req.body);
  res.status(200).json(result);
}
