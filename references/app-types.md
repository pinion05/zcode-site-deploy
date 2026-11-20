# 앱 타입별 스테이지 구성

공통: 스테이지는 `.zcode-site/stage/`, 루트에 `start.sh`, 모든 앱이 `0.0.0.0:3000`에서 `/`에 200으로 응답한다.

## 정적 사이트

```
stage/
├── start.sh            # static 템플릿
├── static-server.mjs   # 의존성 0짜리 정적 파일 서버 (플러그인 템플릿에서 복사)
└── dist/               # 빌드 결과 (index.html, assets/…)
```

- 템플릿 위치: zcode-site 플러그인의 `skills/site-deploy/templates/` (`static.sh`, `static-server.mjs`). `zcode-site.sh`가 찾은 플러그인 디렉토리 아래에서 가져온다
- `SPA_FALLBACK=1`: 클라이언트 라우팅 SPA (모르는 경로 → index.html). `0`: 멀티페이지/정적 export (404)
- base 경로는 반드시 `/`
- API 라우트·SSR 없이 export 가능한 프레임워크면 정적으로 배포한다 — 작고 시작이 빠르다

## Node 서버

```
stage/
├── start.sh            # node 템플릿
├── package.json        # "type":"module" 등이 걸려 있으므로 유지
├── <빌드 결과>          # dist/, .output/, .next/ …
└── node_modules/       # 프로덕션 의존성, linux x64용
```

- 런타임에선 컴파일된 JS만: `ts-node`/`tsx`/개발 서버 금지. `exec node <entry>` 형태로 직접 실행
- **의존성은 크로스 설치** (로컬 `node_modules` 복사 금지 — arm64/darwin 바이너리 때문):
  ```bash
  npm install --omit=dev --os=linux --cpu=x64 --libc=glibc
  ```
- 네이티브 컴파일 패키지(`better-sqlite3`, `bcrypt`, `canvas`…)는 크로스 설치 불가 → 순수 JS 대체품으로 바꾸거나 한계를 사용자에게 설명
- 프레임워크의 self-contained 출력(standalone/node adapter)이 있으면 그걸 쓴다 (작음). 다만 그 안의 네이티브 패키지는 로컬 바이너리이므로 linux x64로 다시 설치
- HTTPS는 앞단 프록시가 처리 → 앱은 plain HTTP, `X-Forwarded-*` 헤더 신뢰 설정만 (`trust proxy` 등)

## Python 서버

```
stage/
├── start.sh            # python 템플릿
├── <앱 코드>            # main.py, app/, templates/ …
└── vendor/             # linux x86-64 휠 (Python 3.12)
```

- 시작은 항상 `python3 -m <tool>`: `vendor/bin` 콘솔 스크립트는 빌드 머신의 인터프리터 경로를 담고 있어 클라우드에서 안 돌아간다
- FastAPI: `exec python3 -m uvicorn main:app --host 0.0.0.0 --port "$PORT"`
- Flask/Django: `exec python3 -m gunicorn --bind "0.0.0.0:$PORT" --workers 2 app:app` (메모리 상태 있으면 worker 1)
- 휠 준비: linux x86-64 + Python 3.12 대상으로 `pip download` 후 `vendor/`에 풀거나 Docker로 준비
- `ALLOWED_HOSTS = ['*']`처럼 host 검증은 완화 — 실제 호스트는 `X-Forwarded-Host`로 온다

## 네이티브 바이너리 (Rust/Go 등)

```
stage/
├── start.sh            # exec ./server 형태
└── server              # linux x86-64 정적 바이너리
```

- 클라우드에 빌드 도구가 없으니 **로컬에서 linux x86-64로 크로스컴파일**한다
- Rust: `x86_64-unknown-linux-musl` 타겟(정적 빌드 — 배포 가장 단순). rustup 타겟이 없으면 Docker `linux/amd64` 컨테이너에서 cargo build
- Go: `GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build`
- TLS 라이브러리 불필요 — HTTPS는 앞단이 처리
- 로컬 macOS에선 그 바이너리가 안 돌아가므로 `check`가 skipped 될 수 있다 → 같은 서버를 로컬에서 실행해 `/` 200을 확인한 뒤 배포
- 배포 시 패키지 검사가 네이티브 바이너리가 linux x86-64인지 검증한다

## 모노레포

앱 하나만 배포한다. 워크스페이스 도구로 그 앱만 빌드하고, 워크스페이스 패키지가 스테이지 안에 실제 파일로 들어가게 한다 (번들된 서버 출력 또는 `pnpm deploy --prod --filter <app>`).
