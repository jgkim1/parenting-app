import path from "node:path";
import cors from "cors";
import express from "express";
import { errorHandler, notFoundHandler } from "./middlewares/error.middleware";
import { apiRouter } from "./routes";

export const app = express();

app.use(cors());
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

// 업로드된 이미지를 정적으로 서빙한다. 실제 파일은 uploads.routes.ts가 관리한다.
app.use("/uploads", express.static(path.join(process.cwd(), "uploads")));

app.use("/api", apiRouter);

app.use(notFoundHandler);
app.use(errorHandler);
