# zcode-site-deploy

ZCode Sites에 웹 프로젝트를 배포하는 방법을 담은 [ZCode](https://z.ai) 스킬.

정적 사이트·Node 서버·Python 서버·네이티브 바이너리(Rust/Go)를 스테이지 패키지(`start.sh` + 실행 파일)로 구성하고, 로컬 검증 후 업로드해 공개 URL(`https://{prefix}-{4자리}.zai-ai.site`)로 만든다.

## 구조

```
zcode-site-deploy/
├── SKILL.md                 # 스킬 본문: 배포 워크플로 6단계
├── references/
│   ├── app-types.md         # 앱 타입별 스테이지 구성 (정적/Node/Python/네이티브)
│   └── limits.md            # 런타임 제약, 패키지 한도, 에러 코드
└── scripts/
    └── zcode-site.sh        # zcode-site CLI 래퍼 (설치된 플러그인 자동 탐지)
```

이 스킬 자체는 문서와 래퍼뿐이다. 실제 CLI와 시작 스크립트 템플릿은 **ZCode 데스크톱의 zcode-site 플러그인**에서 온다 — 래퍼가 설치된 플러그인(최신 버전)을 자동으로 찾아 사용하므로, ZCode를 업데이트해도 스킬을 고칠 필요가 없다.

## 설치

```bash
git clone https://github.com/pinion05/zcode-site-deploy.git
cp -r zcode-site-deploy ~/.agents/skills/
chmod +x ~/.agents/skills/zcode-site-deploy/scripts/zcode-site.sh
```

ZCode를 재시작하면 `"배포해줘"`, `"이거 URL로 올려줘"` 같은 요청에 자동으로 트리거된다.

## 요구 사항

- ZCode 데스크톱 + zcode-site 플러그인 활성화
- Node.js (래퍼가 CLI 실행에 사용)

## 안전 원칙

- 시크릿·환경변수 값(`.env`, 토큰, 키)은 어떤 형태로도 패키지에 들어가지 않는다 — `.env`는 배포 자체가 거부된다
- 배포 전 스테이지에 뭐가 들어가는지 사용자에게 명시하고 동의를 받는다
- 링크를 아는 누구나 접속할 수 있는 공개 사이트가 된다
- `delete`, `prefix` 변경은 되돌릴 수 없어 명시적 확인이 필요하다

## 라이선스

MIT — [LICENSE](LICENSE)

이 스킬은 ZCode Sites 플러그인(Z.ai)의 CLI를 사용하며, 플랫폼 동작 사실(포트·한도·에러 코드)을 문서화한 것이다. 플러그인 코드는 이 저장소에 포함되어 있지 않다.
