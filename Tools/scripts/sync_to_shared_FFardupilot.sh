#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="/home/kk/FFardupilot"
DST_DIR="/mnt/shared/shared_FFardupilot"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

log() { echo "[$(date +%H:%M:%S)] $*"; }
maybe_run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRYRUN: $*"
  else
    "$@"
  fi
}

if [[ ! -d "$SRC_DIR" ]]; then
  echo "SRC_DIR not found: $SRC_DIR" >&2
  exit 1
fi
if [[ ! -d "$DST_DIR" ]]; then
  echo "DST_DIR not found: $DST_DIR" >&2
  exit 1
fi

copy_board_artifacts() {
  local rel_bin_dir="$1"  # e.g. build/MatekH743/bin
  local src_bin_dir="$SRC_DIR/$rel_bin_dir"
  local dst_bin_dir="$DST_DIR/$rel_bin_dir"

  mkdir -p "$dst_bin_dir"

  # Copy the newest "with bootloader" hex (filename may be prefixed by version/board)
  local latest_hex
  latest_hex="$(ls -t "$src_bin_dir/"*with_bl*.hex 2>/dev/null | head -n 1 || true)"
  if [[ -n "$latest_hex" ]]; then
    rm -f "$dst_bin_dir/"*with_bl*.hex 2>/dev/null || true
    cp -a "$latest_hex" "$dst_bin_dir/"
    log "COPIED: ${latest_hex#"$SRC_DIR/"}"
  else
    log "artifact missing (hex): ${rel_bin_dir}/*with_bl*.hex"
  fi

  # Copy stable names if present
  for f in "arduplane.bin" "arduplane.apj"; do
    local src="$src_bin_dir/$f"
    local dst="$dst_bin_dir/$f"
    if [[ -f "$src" ]]; then
      cp -a "$src" "$dst"
      log "COPIED: ${rel_bin_dir}/${f}"
    else
      log "artifact missing (file): ${rel_bin_dir}/${f}"
    fi
  done
}

log "Sync code (rsync) to $DST_DIR (DRY_RUN=$DRY_RUN)"

# Code sync: copy only source/doc/etc; skip build directory. rsync itself will skip unchanged files.
maybe_run rsync -a --delete \
  --exclude 'build/**' \
  --exclude '.waf-*' \
  --exclude '.lock-waf_*' \
  "$SRC_DIR/" "$DST_DIR/"

log "Sync build artifacts (latest with_bl hex + arduplane.bin/apj)"
copy_board_artifacts "build/MatekH743/bin"
copy_board_artifacts "build/MatekF405-Wing/bin"

log "Sync finished."

