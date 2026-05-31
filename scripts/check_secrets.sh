#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Running secret leak checks..."

# 1) Shared schemes must never contain REE_API_KEY.
if rg -n "REE_API_KEY" PrecioLuzApp.xcodeproj/xcshareddata >/dev/null 2>&1; then
  echo "ERROR: REE_API_KEY found in xcshareddata (shared scheme)."
  rg -n "REE_API_KEY" PrecioLuzApp.xcodeproj/xcshareddata || true
  exit 2
fi

# 2) Detect hardcoded REE_API_KEY assignments in tracked files.
leaks="$(
  git grep -nE 'REE_API_KEY[[:space:]]*=' -- . ':(exclude).env' ':(exclude).env.*' \
    | grep -v 'REE_API_KEY=your_local_token' \
    || true
)"
if [[ -n "$leaks" ]]; then
  echo "ERROR: Hardcoded REE_API_KEY assignment found in tracked files."
  echo "$leaks"
  exit 3
fi

echo "OK: no API key leaks detected in shared/tracked files."
