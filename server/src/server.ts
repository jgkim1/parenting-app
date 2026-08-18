import { app } from "./app";
import { env } from "./config/env";

app.listen(env.PORT, () => {
  console.log(`서버가 http://localhost:${env.PORT} 에서 실행 중입니다.`);
});
