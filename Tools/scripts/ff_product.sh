#!/usr/bin/env bash
# FFardupilot product branch helper
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

GCC_PATH="/usr/lib/ccache:/opt/gcc-arm-none-eabi-10-2020-q4-major/bin"
PY="${PYTHON:-python3}"
GIT="${GIT:-/usr/bin/git}"

# Layer 1: upstream anchors (read-only)
BASE_BRANCHES=(
    base/ardupilot.4.5.7
    base/ardupilot.4.8.5dev
)

# Layer 2: independent feature modules (cherry-pick / merge onto any version)
FEATURE_BRANCHES=(
    feature/FF_RADAR
    feature/FF_TKOFF
)

# Layer 3: product = base + feature(s)
PRODUCT_BRANCHES=(
    ardupilot.4.5.7_FF_RADAR
    ardupilot.4.5.7_FF_RADAR_TKOFF
    ardupilot.4.8.5dev_FF_RADAR
    ardupilot.4.8.5dev_FF_RADAR_TKOFF
)

usage() {
    cat <<EOF
Usage: $0 list
       $0 checkout <branch>
       $0 build <board> [branch]

Branch layout (3 layers):
  base/ardupilot.*              Pure ArduPilot version anchor
  feature/FF_RADAR              Formation radar only (independent module)
  feature/FF_TKOFF              Hand-launch TKOFF_RC_THR only (independent module)

Products (version + features):
  ardupilot.4.5.7_FF_RADAR           4.5.7 + formation radar
  ardupilot.4.5.7_FF_RADAR_TKOFF     4.5.7 + formation + TKOFF
  ardupilot.4.8.5dev_FF_RADAR        4.8.x-dev + formation (+ H7A3 INA2xx)
  ardupilot.4.8.5dev_FF_RADAR_TKOFF  4.8.x-dev + formation + TKOFF
EOF
}

cmd_list() {
    echo "=== Layer 1: Base (upstream anchors, do not develop here) ==="
    for b in "${BASE_BRANCHES[@]}"; do
        if "$GIT" show -s --format='%h %s' "$b" >/dev/null 2>&1; then
            printf '  %-36s ' "$b"
            "$GIT" show -s --format='%h %s' "$b"
        else
            echo "  $b (missing)"
        fi
    done
    echo ""
    echo "=== Layer 2: Features (independent modules) ==="
    for b in "${FEATURE_BRANCHES[@]}"; do
        if "$GIT" show -s --format='%h %s' "$b" >/dev/null 2>&1; then
            printf '  %-36s ' "$b"
            "$GIT" show -s --format='%h %s' "$b"
        else
            echo "  $b (missing)"
        fi
    done
    echo ""
    echo "=== Layer 3: Products (checkout & build) ==="
    for b in "${PRODUCT_BRANCHES[@]}"; do
        if "$GIT" show -s --format='%h %s' "$b" >/dev/null 2>&1; then
            printf '  %-36s ' "$b"
            "$GIT" show -s --format='%h %s' "$b"
        else
            echo "  $b (missing)"
        fi
    done
    echo ""
    echo "Current: $("$GIT" branch --show-current) @ $("$GIT" rev-parse --short HEAD)"
}

cmd_checkout() {
    local branch="$1"
    "$GIT" checkout "$branch"
    echo "Checked out: $branch"
    "$GIT" log -1 --oneline
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
