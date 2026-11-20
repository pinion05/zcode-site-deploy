---
name: zcode-site-deploy
description: ZCode Sites에 웹 프로젝트를 배포해 공개 URL을 만들고 관리하는 방법. 정적 사이트·Node·Python·네이티브 바이너리(Rust/Go)를 스테이지 패키지로 구성해 체크 후 업로드. "배포해줘", "사이트 올려줘", "URL로 보여줘", "이거 공유 가능?", "ZCode Sites", "deploy", "publish" 같은 배포·공유 요청에 사용. 단, 운영 프로젝트(Dockerfile·CI·Vercel 등 자체 배포 체계가 있는 경우)에는 쓰지 않는다. ZCode 데스크톱 설치 환경에서만 동작.
---

# ZCode Sites 배포

데모·프로토타입·소형 도구를 ZCode 클라우드에 올려 공개 링크를 만드는 스킬.
모든 빌드는 로컬에서 끝내고, 클라우드는 패키지를 `/app`에 풀어 `bash start.sh`로 실행만 한다.

## 언제 쓰나

- **쓴다**: 이 대화에서 만든 새 프로젝트, 데모, 목업, 공유용 소형 도구
- **안 쓴다**: 운영 프로젝트 — `Dockerfile`, `vercel.json`, `fly.toml`, `Procfile`, CI 배포 워크플로, 운영 도메인 설정이 있으면 그 프로젝트의 자체 배포 프로세스를 따른다. 애매하면 사용자에게 묻는다.

## CLI 실행

이 스킬 디렉토리의 래퍼가 로컬에 설치된 zcode-site 플러그인 CLI(최신 버전)를 자동으로 찾아 실행한다:

```bash
"<skill-dir>/scripts/zcode-site.sh" <command>
```

전체 명령 레퍼런스는 `zcode-site.sh help`로 본다. 명령이 실패하면 help를 읽고 원인을 파악한다.

## 워크플로

### 1. 프로젝트 파악

런타임에 뭘 필요로 하는지로 분류하고 `references/app-types.md`의 해당 섹션을 읽는다:

- **정적**: 빌드 결과가 HTML/CSS/JS뿐 (프레임워크가 정적 export 가능하면 무조건 그렇게)
- **Node 서버**: 요청마다 서버 코드 실행 (SSR, API 라우트)
- **Python 서버**: FastAPI/Flask/Django 등
- **네이티브 바이너리**: Rust/Go 등 — linux x86-64로 크로스컴파일한 실행 파일

DB 서버, 시크릿 주입, 상시 백그라운드 워커가 필요하면 지원하지 않는다. 대안(SQLite를 `$DATA_DIR`에, 정적 빌드)을 제시하고 사용자와 합의한다.

### 2. 스테이지 구성

프로젝트 도구로 빌드한 뒤 **실행에 필요한 것만** 새 `.zcode-site/stage/`에 복사한다 (재배포마다 스테이지는 처음부터 다시 만든다). 스테이지 루트가 곧 클라우드의 `/app`이다.

- 로컬 `node_modules`, 가상환경 통째로 복사 금지 — macOS/arm64 바이너리가 섞여 있고 클라우드는 linux x86-64다. 크로스 설치 방법은 `references/app-types.md`
- `.env`는 패키징 거부 대상. 시크릿은 어떤 형태로도 넣지 않는다
- `.zcode-site/`를 `.gitignore`에 추가한다
- 스테이지에 민감해 보이는 파일(데이터·내부 문서)이 들어갈 때는 사용자에게 이름을 짚어 확인받는다

### 3. start.sh 작성

스테이지 루트에 `start.sh`. 규칙 4개 — 어긋하면 클라우드에서 죽는다:

1. **`exec`로 포어그라운드 실행** — `&`, `nohup`, pm2 금지. 프로세스가 죽으면 사이트가 죽는 구조
2. **`0.0.0.0:3000` 바인딩** — 127.0.0.1 리스닝은 헬스체크 실패
3. **설치·빌드·다운로드 금지** — `npm install` 등은 클라우드에 빌드 도구가 없어 실패. 의존성은 전부 패키지 안에
4. **LF 줄바꿈, 스크립트 맨 처음에 자기 디렉토리로 `cd`**

쓰기 파일은 전부 `$DATA_DIR` 아래로 (인스턴스 재시작마다 사라지는 임시 저장소).

### 4. 로컬 검증

```bash
"<skill-dir>/scripts/zcode-site.sh" check .zcode-site/stage
```

`{"status":"live","httpStatus":200}`가 나와야 한다. `START_FAILED`면 로그를 읽고 고친다. linux 전용 바이너리가 있어 로컬 검증이 `skipped`되면, 같은 시작 명령을 로컬 환경에서 직접 돌려 `/`의 200을 확인한다.

### 5. 사용자 확인 후 배포

**업로드 전에 반드시 사용자의 명시적 동의를 받는다.** 알려줄 것:

- 스테이지 내용(빌드 산출물 + 서버 소스)이 ZCode 클라우드로 업로드됨
- 링크를 아는 누구나 열 수 있는 공개 사이트가 됨
- 시크릿은 업로드되지 않음

첫 배포 (프로젝트 루트에 `.zcode-site.json`이 없을 때):

```bash
"<skill-dir>/scripts/zcode-site.sh" deploy .zcode-site/stage --new --name "<표시 이름>" --prefix <도메인 접두사>
```

- `--prefix`: 프로젝트 내용을 나타내는 4–30자 소문자/숫자/하이픈 (`happy-birthday` O, `app` X). 최종 주소는 `{prefix}-{랜덤4자}`이고 재배포해도 유지된다
- 이후 재배포: `deploy .zcode-site/stage` (같은 주소)
- 배포는 수 분 걸릴 수 있다 — 완료될까지 기다린다

실패 시: `PACKAGE_CHECK_FAILED`는 `error.data.problems`를 전부 고치고 재시도 (아무것도 업로드되지 않은 상태). `WARMUP_FAILED`는 `logs <deploymentId>`를 보고 2–6단계를 고친다. 할당량 오류(exit 3)는 재시도하지 않고 사용자에게 알린다.

### 6. 결과 보고

URL, 변경한 내용과 이유, 검증 방법(check 결과 또는 로컬 실행), 클라우드에서 작동하지 않는 기능을 함께 보고한다.

## 사이트 관리

`status | logs <id> | offline | online | rename <name> | prefix <p> | analytics | list | usage | delete --site <id>`

- `delete`와 `prefix` 변경은 되돌릴 수 없다 — 사용자에게 사이트명/URL을 짚어주고 명시적 확인 후에만 실행
- 상태: `pending`(미배포) / `online` / `offline`

## 더 읽기

- 앱 타입별 스테이지 구성·의존성 설치: `references/app-types.md`
- 런타임 제약·한도·에러 코드: `references/limits.md`
