# 육아 앱 프로젝트 현황

> 이 문서는 새 세션이 시작될 때 지금까지의 작업을 빠르게 파악하기 위한 문서입니다.
> 시간 기반 자동 갱신은 아니고(클라우드 스케줄러는 로컬 파일에 접근할 수 없어 사용 불가),
> 이 프로젝트에서 의미 있는 작업을 할 때마다 Claude가 매번 갱신합니다.
> **마지막 갱신: 2026-08-18 (백엔드를 Spring Boot(Java)+MySQL로 신규 이관, Maven 빌드 도입)**

## 한눈에 보기

- **무엇을 만드는 중인가**: 육아용품 제품 소개 + 커뮤니티 + 자체 쇼핑몰을 하나로 묶은 앱
- **구조**: `app/`(Flutter, web+iOS+Android 단일 코드베이스) + **백엔드 2종 병행**(아래 "백엔드 이중화 안내" 절 참고)
  - `server-java/` — Spring Boot + MySQL. **지금 Flutter 앱이 실제로 연결된 곳(활성).**
  - `server/` — 기존 Node.js/Express/Prisma + PostgreSQL. 코드는 그대로 보존, 앱은 더 이상 이 서버를 바라보지 않음.
- **진행 상태**: README에 정의된 세 축(제품 소개·커뮤니티·쇼핑)과 부가 기능(리뷰, 자녀 프로필, 광고, 카카오/구글 소셜 로그인, 관리자 모드)까지 Node 버전에서 전부 구현되어 있었고, 이번에 그 기능 전체를 Spring Boot로 이관했다. 결제 연동과 실명인증만 의도적으로 범위 밖(실명인증은 외부 유료 인증대행사 계약이 필요해 보류).
- **⚠️ git 커밋이 아직 하나도 없음**: 저장소 전체가 untracked 상태(`master` 브랜치, 커밋 0개). GitHub 저장소 연결을 진행 중이나 `gh auth login` 완료 대기 중(아래 "GitHub 연결 상태" 절 참고).

## 백엔드 이중화 안내 (왜 서버가 두 개인가)

사용자가 "데이터베이스를 MySQL로, 로직을 Spring(Java) 기반으로 바꾸고 Maven으로 빌드해달라"고
명시적으로 요청해 기존 Node.js/PostgreSQL 서버는 그대로 둔 채 **새 폴더(`server-java/`)에
Spring Boot + MySQL로 전체 백엔드를 새로 만들었다.** 기존 서버를 지우지 않은 이유는 되돌릴 수
없는 작업(삭제)을 피하기 위해서다 — 필요 없어지면 사용자가 직접 정리하거나 삭제를 요청하면 된다.

| | `server/` (기존) | `server-java/` (신규, 활성) |
|---|---|---|
| 언어/프레임워크 | Node.js + TypeScript + Express | Java 21 + Spring Boot 3.5 |
| DB | PostgreSQL | MySQL 8 |
| ORM | Prisma | Spring Data JPA(Hibernate) |
| 빌드 도구 | npm | **Maven** |
| 인증 | JWT(jsonwebtoken) + bcrypt | JWT(jjwt) + Spring Security BCrypt |
| 포트 | 4000 | **8080** |
| Flutter 앱 연결 여부 | ❌ (더 이상 연결 안 됨) | ✅ (`ApiEndpoints.baseUrl`이 여기를 가리킴) |
| 테스트 | Vitest+Supertest 80개 | JUnit5+MockMvc 20개(핵심 시나리오 위주, 아래 참고) |

**같은 기능을 두 번 유지보수해야 하는가?** 아니다 — `server/`는 이제 참고용 스냅샷이고,
앞으로 기능 추가·수정은 `server-java/`에서 진행하면 된다. 다만 두 서버 다 로컬에 남아있으니
포트 충돌 걱정 없이 필요하면 언제든 옛 버전(Node, 4000번)도 켜서 비교해볼 수 있다.

## 기술 스택

- **백엔드(활성, `server-java/`)**: Java 21, Spring Boot 3.5.14, Spring Data JPA(Hibernate), Spring Security, MySQL 8, JWT 인증(jjwt, access+refresh 로테이션), Maven 3.9
- **백엔드(보존, `server/`, 더 이상 앱이 쓰지 않음)**: Node.js, TypeScript, Express, Prisma, PostgreSQL
- **프론트엔드**: Flutter (Riverpod, go_router, dio, flutter_secure_storage, image_picker, google_sign_in, kakao_flutter_sdk_user, url_launcher)
- **테스트**: `server-java` JUnit5+MockMvc(20개, 핵심 시나리오), `server`(Node, 참고용) Vitest+Supertest(80개), Flutter flutter_test+mocktail(73개)

## 완료된 기능

| 모듈 | 서버 | 앱 | 비고 |
|---|---|---|---|
| 인증 | ✅ 회원가입/로그인/refresh 로테이션/로그아웃/카카오·구글 소셜 로그인 | ✅ | refresh 토큰에 `jti` 랜덤값 추가해 "같은 초에 발급되면 토큰이 완전히 같아지는" 재사용탐지 무력화 버그를 테스트 작성 중 발견·수정함. 소셜 로그인은 실계정 이메일 충돌 시 자동 연동하지 않고 명시적으로 거부(계정 탈취 방지) |
| 상품(쇼핑) | ✅ 카테고리/목록(검색·필터·페이지네이션)/상세/리뷰 CRUD(평균평점 포함)/관리자 수정·비활성화 | ✅ 관리자 등록/수정 화면 포함 | 등록은 SELLER·ADMIN, 수정은 소유 SELLER 또는 ADMIN. 삭제는 하드 삭제가 아니라 `isActive` 토글(주문 이력 보존을 위해 소프트 삭제) |
| 육아 정보(아티클) | ✅ 카테고리/목록/상세(조회수)/관리자 수정·삭제 | ✅ 관리자 등록/수정 화면 포함 | 등록·수정·삭제 모두 ADMIN 전용. 삭제는 하드 삭제(주문처럼 참조하는 데이터가 없어 안전), 비공개 전환(`isActive`)도 지원 |
| 광고 | ✅ `/api/ads` CRUD(placement별) | ✅ 관리자 등록/수정/삭제 화면 + `AdBanner` 실데이터 연동 | 관리자가 올린 광고가 있으면 실제로 노출, 없으면 기존 플레이스홀더로 자동 대체. `linkUrl`이 있으면 탭 시 `url_launcher`로 새 탭에서 실제 이동(웹은 새 탭, 모바일은 외부 브라우저/앱) |
| 관리자 모드 | ✅ role=ADMIN 전용 엔드포인트 | ✅ `/admin` 라우트 그룹 | "내 정보" 탭에 ADMIN 계정에게만 "관리자 모드" 진입 카드 노출. go_router redirect가 비-ADMIN의 `/admin/*` 접근을 `/home`으로 되돌림. 카테고리 자체를 만드는 UI는 아직 없음(여전히 `prisma/seed.ts`로만 생성) |
| 커뮤니티 | ✅ 게시글·댓글·좋아요, 이미지 업로드(멀티파트), 수정/삭제(소유권 검증) | ✅ | 이미지 업로드가 실제로 UI에 연결된 콘텐츠 타입(상품/아티클/광고도 이제 업로드 지원) |
| 장바구니/주문 | ✅ 재고검증, 담기/수량변경/삭제, 주문 생성 트랜잭션(재고차감+장바구니비우기+가격스냅샷) | ✅ | 주문 상태는 `PENDING_PAYMENT`까지만. **결제(PG) 연동 없음** — README에 명시된 의도적 범위 제외 |
| 자녀 프로필 | ✅ CRUD, 소유권 검증 | ✅ | "내 정보" 탭에 통합 |
| 홈 UI | - | ✅ | 하단 탭 5개(투데이/육아 정보/커뮤니티/쇼핑/내 정보)로 리팩터링. `IndexedStack`이라 탭 전환 시 스크롤/필터/검색 상태 유지됨 |
| 투데이 대시보드 | - | ✅ | 세 도메인의 최신 콘텐츠 요약 + "더보기"로 탭 전환 |
| 자동화 테스트 | ✅ Java 20개(핵심 시나리오) / Node 80개(보존, 참고용) | ✅ 73개 | Java 쪽은 회원가입/로그인/토큰로테이션, 상품 권한·리뷰중복방지, 주문 트랜잭션(재고차감), 커뮤니티 좋아요·댓글 권한 위주로 작성. Node의 80개를 전부 1:1로 옮기진 않았음(아래 "다음 단계" 참고) |
| 소셜 로그인(카카오/구글) | ✅ `/api/auth/kakao`, `/api/auth/google` | ✅ 로그인 화면에 버튼 추가 | **실제 자격증명(앱 키) 미설정 상태** — 아래 "소셜 로그인 자격증명 안내" 절 참고 |

## 관리자 모드 안내

- **진입 경로**: 앱에서 ADMIN 역할 계정으로 로그인 → 하단 탭 "내 정보" → "관리자 모드" 카드 탭 → `/admin`에서 상품/육아정보/광고 세 메뉴 선택.
- **시드 관리자 계정**: `admin@example.com` / `password123` (`server/prisma/seed.ts`에서 생성).
- **서버 권한 모델**: 상품 수정은 `requireRole("SELLER", "ADMIN")` + 서비스 레이어에서 "ADMIN이거나 본인이 등록한 상품"인지 재검증. 아티클·광고는 전부 `requireRole("ADMIN")`.
- **"삭제" 버튼의 실제 동작이 항목마다 다름**: 상품은 주문 이력이 상품을 참조하므로 하드 삭제 대신 `isActive:false`로 판매만 중지시킨다(관리자 화면에서는 다시 노출 가능). 아티클·광고는 참조하는 데이터가 없어 실제 하드 삭제(`DELETE`)를 수행한다.
- **목록 조회 방식**: 관리자 목록 화면은 페이지네이션 없이 `pageSize=50`(서버 zod 스키마 상한)으로 한 번에 불러온다. 상품/아티클이 50개를 넘어가면 이 방식으로는 뒤쪽 항목이 안 보이므로, 그 규모가 되면 관리자 목록에도 페이지네이션을 추가해야 한다.

## 알려진 이슈

- **Flutter Web CanvasKit 렌더링 잔상 버그**: 헤드리스 Playwright 테스트 환경에서 이미지가 성공적으로 로드된 게시글 상세 화면에 이전 화면(홈) 콘텐츠가 겹쳐 보이는 현상을 발견했으나, 사용자가 실제 브라우저(Edge)로 직접 확인한 결과 **재현되지 않았음** → 헤드리스 자동화 환경 특유의 아티팩트로 결론. 코드 수정 없이 종료.
- **카테고리 관리 UI가 없음**: 상품 카테고리/아티클 카테고리를 만들거나 수정하는 API·화면이 아직 없어, 새 카테고리가 필요하면 지금은 DB에 직접 넣어야 함(아래 "MySQL에 한글 데이터를 직접 넣을 때 주의" 참고).
- **카카오 로그인은 현재 모바일(Android/iOS) 전용**: 공식 `kakao_flutter_sdk_user` 2.x가 웹에서는 로그인 API 자체를 `UnsupportedError`로 막아둠. 웹에서 카카오 버튼을 누르면 "모바일 앱에서만 이용 가능" 안내만 뜨고 정상 동작함(크래시 없음).
- **구글 로그인도 웹에서는 앱이 직접 로그인 창을 못 띄움**: `google_sign_in` 7.x 웹 구현이 `supportsAuthenticate()=false`라 자체 렌더링 버튼(GIS)을 통해서만 로그인 가능. 모바일에서는 표준 플로우로 동작.
- **Java 서버 쪽 소셜 로그인은 코드만 포팅되어 있고 미검증**: `server-java`의 구글 로그인은 `google-auth-library` 대신 구글의 `tokeninfo` 엔드포인트로 서명을 검증하는 방식으로 단순화해서 옮겼다(추가 의존성 없이 동일한 보안 수준). 카카오는 Node 버전과 동일하게 `kapi.kakao.com/v2/user/me` 조회 방식. 다만 `application.yml`의 `app.google.client-id`가 비어있어 실제 자격증명 없이는 둘 다 동작 확인이 안 된 상태.

## GitHub 연결 상태

✅ **연결 완료.** Private 저장소 https://github.com/jgkim1/parenting-app 로 최초 커밋(370개 파일)을
푸시했다. 로컬 `origin` 리모트가 이미 연결되어 있으니 이후 세션에서는 바로
`git add -A && git commit -m "..." && git push`로 이어서 올리면 된다.
`.env`류 파일은 전부 `.gitignore`에 등록해뒀다(`server/.env`, `server/.env.test`,
`server-java/.env` 등 — `.env.example`만 예시용으로 커밋됨).
이 저장소 로컬 git 사용자 정보는 GitHub 계정 기준으로 설정함(`user.name=KIM JAEGEUN`,
`user.email=jgkim1@users.noreply.github.com`, `--global` 아닌 이 저장소 전용 설정).

## 소셜 로그인 자격증명 안내

- **구글**: [Google Cloud Console](https://console.cloud.google.com)에서 OAuth 클라이언트 ID(웹 애플리케이션 유형)를 발급받아 `server-java/src/main/resources/application.yml`의 `app.google.client-id`와 `app/lib/core/config/social_login_config.dart`의 `googleClientId`에 **동일한 값**을 넣는다.
- **카카오**: [Kakao Developers](https://developers.kakao.com)에서 앱을 등록하고 네이티브 앱 키를 `app/lib/core/config/social_login_config.dart`의 `kakaoNativeAppKey`에 넣는다(서버 쪽 키는 필요 없음).
- 이 앱 키들은 Claude가 대신 발급받을 수 없으므로, 실제 라이브 테스트는 사용자가 키를 발급해 넣은 뒤 진행해야 한다.

## 다음 단계 후보 (우선순위 순은 아님)

1. **Node 서버(`server/`) 테스트 80개를 Java 쪽에도 확장 이관** — 지금 Java 쪽엔 핵심 시나리오 20개만 있음. 자녀 프로필, 아티클/광고 관리자 CRUD, 업로드 등은 아직 통합 테스트가 없음(수동으로는 검증했음).
2. **결제(PG) 연동** — 실제 PG사 계정/API 키 필요. 사용자 확인 후 진행.
3. **카테고리 관리 UI** — 지금은 DB에 직접 넣어야 함.
4. **관리자 목록 페이지네이션** — 상품/아티클이 많아지면 필요.
5. **소셜 로그인 앱 키 발급 및 적용** — 위 "소셜 로그인 자격증명 안내" 절 참고.
6. **`server/`(Node 버전) 처리 방향 결정** — 계속 참고용으로 남길지, 완전히 정리(삭제)할지 사용자 판단 필요. 삭제는 사용자가 명시적으로 요청할 때만 진행.
7. **README.md 갱신** — 아직 Node 버전 실행 절차만 담고 있어, `server-java` 기준으로 다시 써야 함.

## 트러블슈팅 메모

- **새 Flutter 패키지 추가 후 웹에서 `MissingPluginException`이 뜨면**: `flutter pub add`만으로는 웹 플랫폼 플러그인 등록이 갱신되지 않는 경우가 있었다. `flutter clean && flutter pub get` 후 `flutter build web`을 다시 하면 해결된다.
- **MySQL에 한글 데이터를 직접 넣을 때 주의**: Windows의 Git Bash에서 `docker exec ... mysql -e "INSERT ... '한글값' ..."`처럼 한글이 포함된 문자열을 명령줄 인자로 직접 넘기면 콘솔 인코딩 문제로 깨진 채(mojibake) 저장될 수 있다. **UTF-8로 저장한 `.sql` 파일을 만들어서 `cat file.sql | docker exec -i <컨테이너> mysql -uroot -p<비번> --default-character-set=utf8mb4`처럼 파이프로 흘려보내는 방식**을 쓰면 안전하다. API를 거쳐 저장하는 값(Python `urllib` 등으로 보낸 JSON)은 이 문제가 없었다 — 문제는 셸 명령줄 인자 구성 단계에서만 발생한다.
- **JPA 엔티티에서 대용량 텍스트 컬럼에 `lower()`/`LIKE` 검색을 쓰려면 `@Lob`을 피할 것**: Hibernate 6.x는 `@Lob`으로 매핑된 문자열 컬럼(CLOB)에 `lower()` 같은 SQL 함수를 적용하는 걸 애초에 막아둔다(`FunctionArgumentException`). 검색 대상 컬럼은 `@Column(columnDefinition = "TEXT")`로 매핑해야 한다(실제로 `Post.content` 검색 쿼리에서 이 문제를 겪고 고쳤다).
- **Hibernate `@CreationTimestamp`/`@UpdateTimestamp`가 저장 직후 응답에 `null`로 나올 수 있음**: `repository.save()`만 호출하면 flush가 지연되어 반환된 엔티티 객체에 타임스탬프가 아직 안 채워질 수 있다. 생성/수정 직후 그 값을 바로 응답에 담아야 하는 경우 `save()` 대신 **`saveAndFlush()`**를 쓴다.
- **Maven이 winget 저장소에 없음**: `EclipseAdoptium.Temurin.21.JDK`와 `GitHub.cli`는 winget으로 바로 설치됐지만 `Apache.Maven` 패키지는 winget에 없었다. 공식 배포 zip(`https://dlcdn.apache.org/maven/maven-3/<버전>/binaries/apache-maven-<버전>-bin.zip`)을 받아 `%USERPROFILE%\tools`에 풀고 사용자 PATH에 직접 추가하는 방식으로 설치했다.
- **터미널 세션마다 새로 설치한 CLI 도구(java/mvn/gh)의 PATH가 안 잡힐 수 있음**: 이 환경의 Bash 도구는 세션 시작 시점의 PATH 스냅샷을 쓰는 것으로 보여, 설치 직후에는 매 Bash 호출마다 `export PATH="/c/Program Files/Eclipse Adoptium/jdk-21.0.12.8-hotspot/bin:/c/Users/15U470/tools/apache-maven-3.9.16/bin:/c/Program Files/GitHub CLI:$PATH"`를 앞에 붙여줘야 했다.

## 로컬 개발 환경 (2026-08-18 기준 상태)

- **MySQL** (신규, 활성): Docker Compose `server-java/docker-compose.yml` → 컨테이너 `server-java-mysql-1`, 포트 3306, DB `parenting_app`(개발) / `parenting_app_test`(테스트). 계정 `root`/`mysql`.
- **PostgreSQL** (기존, 더 이상 앱이 안 씀): Docker 컨테이너 `server-postgres-1`, 포트 5432. 지우지 않고 그대로 뒀음.
- **백엔드(활성)**: `server-java/`, `localhost:8080` — `mvn spring-boot:run`으로 기동(자동 재시작 없음, 코드 바꾸면 재기동 필요).
- **백엔드(보존, 미사용)**: `server/`, `localhost:4000` — 필요하면 여전히 `npm run dev`로 켤 수 있음.
- **Flutter 웹**: 정적 릴리스 빌드를 `localhost:5174`에서 `python -m http.server`로 서빙하는 방식으로 검증(가장 안정적).
- **시드 계정** (Java 서버, `server-java` MySQL DB 기준): `admin@example.com`(ADMIN) / `seller@example.com`(SELLER) / `customer@example.com`(CUSTOMER), 비밀번호 공통 `password123`. 카테고리 "유아 의류"/"기저귀·물티슈", 아티클 카테고리 "예방접종"/"이유식", 샘플 상품·아티클·광고 1건씩 등록해둠.
- ⚠️ 이 서버/도커/정적서버 프로세스들은 **세션 종료 시 꺼져 있을 수 있음**. 새 세션에서 이어가려면 `docker ps`(mysql 컨테이너 확인), `curl localhost:8080/health`로 먼저 살아있는지 확인할 것.

## 실행/테스트 명령 요약

```bash
# 백엔드 (Spring Boot / Java, 활성)
cd server-java
docker compose up -d                          # MySQL 기동
# PATH에 java/mvn이 없으면: export PATH="/c/Program Files/Eclipse Adoptium/jdk-21.0.12.8-hotspot/bin:/c/Users/15U470/tools/apache-maven-3.9.16/bin:$PATH"
mvn spring-boot:run                            # 개발 서버 기동 (localhost:8080)
mvn test                                       # JUnit5 통합 테스트 (parenting_app_test DB 사용)
mvn package                                    # 배포용 실행 jar 생성 (target/server-0.1.0.jar)

# 백엔드 (Node.js, 보존만 됨 — 더 이상 앱이 쓰지 않음)
cd server && docker compose up -d && npm run dev

# Flutter (baseUrl이 이제 8080을 가리킴)
cd app && flutter build web
python -m http.server 5174 --directory build/web
cd app && flutter test
```

자세한 절차는 `README.md` 참고(단, README는 아직 Node 버전 기준으로만 작성되어 있어 업데이트가 필요함).

## 코드베이스 구조

```
Claude/
├── README.md                # 실행 방법(Node 버전 기준, 갱신 필요)
├── PROJECT_STATUS.md         # 이 문서
├── server/                   # [보존] Node.js + Express + Prisma + PostgreSQL. 더 이상 앱이 안 씀
│   ├── src/modules/          # auth, users, products, articles, ads, cart, orders, community, uploads, children
│   ├── prisma/schema.prisma, prisma/seed.ts
│   └── test/                 # Vitest + Supertest, 80개
├── server-java/               # [활성] Spring Boot + MySQL — Flutter 앱이 실제로 연결된 곳
│   ├── pom.xml
│   ├── docker-compose.yml     # MySQL 8
│   ├── src/main/java/com/parentingapp/server/
│   │   ├── ServerApplication.java
│   │   ├── domain/            # JPA 엔티티 17개 + enum 5개
│   │   ├── repository/        # Spring Data JPA 리포지토리
│   │   ├── common/            # 예외, JWT, Spring Security 설정, 정적 리소스 서빙
│   │   └── {auth,user,product,article,ad,cart,order,community,child,upload}/
│   │       └── (기능별: dto/, *Service.java, *Controller.java)
│   ├── src/main/resources/application.yml, application-test.yml
│   └── src/test/java/com/parentingapp/server/  # JUnit5 + MockMvc, IntegrationTestBase 공용 헬퍼
└── app/
    └── lib/features/          # auth, products, articles, community, cart, orders, children, admin, home
        └── (각 feature: domain/ data/ presentation/)
    └── test/                  # flutter_test + mocktail
```

## 이 문서를 갱신하는 방법

시간 기반 자동 갱신(크론)은 쓰지 않습니다 — 이 프로젝트는 원격 저장소가 없는 로컬 전용
저장소라, 클라우드 스케줄러가 이 파일에 접근할 방법이 없기 때문입니다. 대신 **이 프로젝트에서
의미 있는 작업(기능 추가/버그 수정/구조 변경 등)을 마칠 때마다 Claude가 이 문서를 갱신**하기로
사용자와 합의했습니다. 만약 이 문서가 오래돼 보이면(마지막 갱신일이 최근 작업과 안 맞으면) 새
세션에서 "PROJECT_STATUS.md 갱신해줘"라고 요청해도 됩니다.
