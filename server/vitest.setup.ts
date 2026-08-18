import path from "node:path";
import dotenv from "dotenv";

// src/config/env.ts가 나중에 dotenv/config로 .env를 불러오지만, dotenv는 이미
// 설정된 process.env 값을 덮어쓰지 않으므로 여기서 먼저 .env.test를 로드해두면
// 테스트 전용 DB/시크릿이 우선 적용된다.
dotenv.config({ path: path.resolve(__dirname, ".env.test") });
