#!/usr/bin/env bash
# FFardupilot product branch helper
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

GCC_PATH="/usr/lib/ccache:/opt/gcc-arm-none-eabi-10-2020-q4-major/bin"
PY="${PYTHON:-python3}"

PRODUCT_BRANCHES=(
    formationflt-4.5.7
    ardupilot.4.8.5dev_FF_RADAR
    tkoff-4.5.7
    tkoff-4.8.0-dev
)

FEATURE_BRANCHES=(
    feature/formation-radar
    feature/takeoff-rc-throttle
)

BASE_BRANCHES=(
    base/plane-4.5.7
    base/plane-4.8.0-dev
)

usage() {
    cat <<EOF
Usage: $0 list
       $0 checkout <branch>
       $0 build <board> [branch]

Product branches (version + features):
  formationflt-4.5.7           ArduPlane 4.5.7 + formation radar (legacy name)
  ardupilot.4.8.5dev_FF_RADAR  ArduPlane 4.8.x-dev + formation radar (+ H7A3 INA2xx)
  tkoff-4.5.7                  4.5.7 + formation + TKOFF_RC_THR
  tkoff-4.8.0-dev              4.8.x-dev + formation + TKOFF_RC_THR

Feature branches (for isolated development):
  feature/formation-radar
  feature/takeoff-rc-throttle
EOF
}

cmd_list() {
    echo "=== Base (read-only anchors) ==="
    for b in "${BASE_BRANCHES[@]}"; do
        if git show -s --format='%h %s' "$b" >/dev/null 2>&1; then
            printf '  %-28s ' "$b"
            git show -s --format='%h %s' "$b"
        else
            echo "  $b (missing)"
        fi
    done
    echo ""
    echo "=== Features ==="
    for b in "${FEATURE_BRANCHES[@]}"; do
        if git show -s --format='%h %s' "$b" >/dev/null 2>&1; then
            printf '  %-28s ' "$b"
            git show -s --format='%h %s' "$b"
        else
            echo "  $b (missing)"
        fi
    done
    echo ""
    echo "=== Products (checkout & build) ==="
    for b in "${PRODUCT_BRANCHES[@]}"; do
        if git show -s --format='%h %s' "$b" >/dev/null 2>&1; then
            printf '  %-28s ' "$b"
            git show -s --format='%h %s' "$b"
        else
            echo "  $b (missing)"
        fi
    done
    echo ""
    echo "Current: $(git branch --show-current) @ $(git rev-parse --short HEAD)"
}

cmd_checkout() {
    local branch="$1"
    git checkout "$branch"
    echo "Checked out: $branch"
    git log -1 --oneline
}

cmd_build() {
    local board="$1"
    local branch="${2:-}"
    if [[ -n "$branch" ]]; then
        cmd_checkout "$branch"
    fi
    export PATH="$GCC_PATH:$PATH"
    export GIT_EXEC_PATH="${GIT_EXEC_PATH:-/usr/lib/git-core}"
    "$PY" ./waf configure --board "$board"
    "$PY" ./waf plane
    echo ""
    echo "Firmware: $ROOT/build/$board/bin/arduplane_with_bl.hex"
    grep THISFIRMWARE ArduPlane/version.h || true
}

case "${1:-}" in
    list)     cmd_list ;;
    checkout) [[ $# -ge 2 ]] || { usage; exit 1; }; cmd_checkout "$2" ;;
    build)    [[ $# -ge 2 ]] || { usage; exit 1; }; cmd_build "$2" "${3:-}" ;;
    *)        usage; exit 1 ;;
esac
