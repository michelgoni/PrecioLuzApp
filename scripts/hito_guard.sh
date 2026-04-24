#!/usr/bin/env bash
set -euo pipefail

STATUS_FILE="${STATUS_FILE:-docs/hito-status.json}"

usage() {
  cat <<'EOF'
Usage:
  scripts/hito_guard.sh can-continue
  scripts/hito_guard.sh mark-waiting <issue> <increment> [note]
  scripts/hito_guard.sh mark-approved [note]
  scripts/hito_guard.sh show
EOF
}

require_file() {
  if [[ ! -f "$STATUS_FILE" ]]; then
    echo "ERROR: status file not found: $STATUS_FILE"
    echo "Create it or set STATUS_FILE env var."
    exit 1
  fi
}

json_get() {
  local key="$1"
  awk -F'"' -v k="$key" '$2 == k { print $4; exit }' "$STATUS_FILE"
}

write_status() {
  local issue="$1"
  local increment="$2"
  local state="$3"
  local note="$4"
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  cat > "$STATUS_FILE" <<EOF
{
  "updatedAt": "$now",
  "issue": "$issue",
  "increment": "$increment",
  "state": "$state",
  "note": "$note"
}
EOF
}

command="${1:-}"
require_file

case "$command" in
  can-continue)
    state="$(json_get state)"
    if [[ "$state" == "waiting_user_review" ]]; then
      issue="$(json_get issue)"
      increment="$(json_get increment)"
      echo "BLOCKED: current status is waiting_user_review."
      echo "Pending review for issue '$issue', increment '$increment'."
      echo "Run: scripts/hito_guard.sh mark-approved \"<user confirmation>\""
      exit 2
    fi
    echo "OK: can continue (state=$state)."
    ;;
  mark-waiting)
    issue="${2:-}"
    increment="${3:-}"
    note="${4:-Checkpoint done; waiting user review.}"
    if [[ -z "$issue" || -z "$increment" ]]; then
      echo "ERROR: issue and increment are required."
      usage
      exit 1
    fi
    write_status "$issue" "$increment" "waiting_user_review" "$note"
    echo "Status updated: waiting_user_review ($issue / $increment)."
    ;;
  mark-approved)
    note="${2:-User validated current increment.}"
    issue="$(json_get issue)"
    increment="$(json_get increment)"
    write_status "$issue" "$increment" "approved" "$note"
    echo "Status updated: approved."
    ;;
  show)
    cat "$STATUS_FILE"
    ;;
  *)
    usage
    exit 1
    ;;
esac
