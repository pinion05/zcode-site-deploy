#!/usr/bin/env bash
# zcode-site CLI 래퍼: 로컬에 설치된 ZCode Sites 플러그인(최신 버전)을 찾아 실행한다.
#
# 사용법:
#   zcode-site.sh <command> [args...]   # CLI 실행 (예: check, deploy, status)
#   zcode-site.sh --plugin-dir          # 플러그인 루트 디렉토리 경로 출력 (템플릿 복사용)
#
# 의존: ZCode 데스크톱의 zcode-site 플러그인 + Node.js. 환경변수·시크릿은 사용하지 않는다.
set -euo pipefail

PLUGIN_ROOTS=(
  "$HOME/.zcode/cli/plugins/cache/zcode-plugins-official/zcode-site"
)

find_plugin_dir() {
  local root latest
  for root in "${PLUGIN_ROOTS[@]}"; do
    [[ -d "$root" ]] || continue
    latest="$(ls -1 "$root" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1 || true)"
    if [[ -n "${latest:-}" && -f "$root/$latest/scripts/zcode-site.mjs" ]]; then
      printf '%s\n' "$root/$latest"
      return 0
    fi
  done
  return 1
}

if ! plugin_dir="$(find_plugin_dir)"; then
  # 플러그인 캐시에 없으면 PATH에 있는지 확인
  if command -v zcode-site >/dev/null 2>&1; then
    exec zcode-site "$@"
  fi
  echo "zcode-site 플러그인을 찾을 수 없습니다." >&2
  echo "ZCode 데스크톱(z.ai)을 설치하고 zcode-site 플러그인이 활성화되어 있는지 확인하세요." >&2
  exit 127
fi

if [[ "${1:-}" == "--plugin-dir" ]]; then
  printf '%s\n' "$plugin_dir"
  exit 0
fi

exec node "$plugin_dir/scripts/zcode-site.mjs" "$@"
