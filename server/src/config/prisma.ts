import { PrismaClient } from "@prisma/client";

// 개발 환경에서 핫 리로드 시 커넥션이 중복 생성되지 않도록 싱글턴으로 관리한다.
export const prisma = new PrismaClient();
