#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/check_tca_warnings.sh --log <build-log-path>

Description:
  Scans an xcodebuild log and fails when TCA-related warnings/deprecations are found.
EOF
}

log_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --log)
      shift
      log_path="${1:-}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift || true
done

if [[ -z "$log_path" ]]; then
  echo "ERROR: --log is required."
  usage
  exit 1
fi

if [[ ! -f "$log_path" ]]; then
  echo "ERROR: log file not found: $log_path"
  exit 1
fi

tca_pattern='(warning:|deprecated:).*(ComposableArchitecture|swift-composable-architecture|WithViewStore|Store\(|@ObservableState|CasePathable|TestStore)'

match_output="$(rg -n -i "$tca_pattern" "$log_path" || true)"
match_count="$(printf '%s' "$match_output" | awk 'NF { count += 1 } END { print count + 0 }')"

if [[ "$match_count" -gt 0 ]]; then
  echo "TCA warnings/deprecations: $match_count (blocking)"
  printf '%s\n' "$match_output"
  exit 2
fi

echo "TCA warnings/deprecations: 0"
