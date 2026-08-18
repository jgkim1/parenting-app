# 육아 앱 (제품 소개 · 커뮤니티 · 쇼핑)

육아용품 제품 소개, 커뮤니티, 자체 쇼핑몰 기능을 제공하는 앱입니다.

## 구조

```
Claude/
├── app/       # Flutter (web + iOS + Android 단일 코드베이스)
├── server/    # Node.js + TypeScript + Express + Prisma 백엔드
└── docs/      # API 계약(OpenAPI), ERD 등 문서
```

## 기술 스택

- **백엔드**: Node.js, TypeScript, Express, Prisma, PostgreSQL, JWT 인증
- **프론트엔드**: Flutter (Riverpod, go_router, dio)

## 로컬 실행

### 백엔드

```bash
cd server
cp .env.example .env
docker compose up -d      # PostgreSQL 실행
npm install
npx prisma migrate dev
npm run dev
```

### Flutter 앱

```bash
cd app
flutter pub get
flutter run -d chrome      # 웹
flutter run                # 연결된 기기/에뮬레이터
```

### 백엔드 테스트

Vitest + Supertest로 API를 실제 요청/응답 수준에서 검증합니다. 개발용 DB와 분리된
`parenting_app_test` DB를 사용하므로, 시드 데이터나 개발 중 데이터에 영향을 주지 않습니다.

```bash
cd server
docker exec <postgres-컨테이너명> psql -U postgres -c "CREATE DATABASE parenting_app_test"  # 최초 1회
npm test          # 테스트 DB에 마이그레이션 적용 후 전체 테스트 실행
npm run test:watch  # 워치 모드
```

인증, 상품/리뷰(권한·중복 방지), 장바구니/주문(재고 검증·트랜잭션), 커뮤니티(게시글·댓글·좋아요
동시성), 자녀 프로필(소유권 검증)을 다룹니다.

### Flutter 테스트

`flutter_test` + `mocktail`로 도메인 모델의 JSON 파싱과 Riverpod 컨트롤러(상태 전이·에러 처리·
페이지네이션)를 네트워크 없이 검증합니다.

```bash
cd app
flutter test
```

`test/features/**/domain`은 서버 응답 형태의 JSON을 모델로 파싱하는 로직을, `presentation`은
리포지토리를 목으로 대체해 로딩/성공/실패 상태 전이와 댓글·좋아요 낙관적 업데이트 같은 로직을
다룹니다.

## 참고

- 결제(PG) 연동은 이번 범위에서 제외되어 있습니다. 주문은 `PENDING_PAYMENT` 상태로 생성됩니다.
