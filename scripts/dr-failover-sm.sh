#!/usr/bin/env bash

set -euo pipefail

# DR failover Step Functions helper.
# Defaults are aligned with this repo's prod-dr deployment.

DR_REGION="${DR_REGION:-eu-central-1}"
ACCOUNT_ID="${ACCOUNT_ID:-495711089104}"
NAME_PREFIX="${NAME_PREFIX:-prod-dr-failover}"
TARGET_NODE_DESIRED="${TARGET_NODE_DESIRED:-3}"
TARGET_REPLICAS="${TARGET_REPLICAS:-3}"

STATE_MACHINE_ARN="${STATE_MACHINE_ARN:-arn:aws:states:${DR_REGION}:${ACCOUNT_ID}:stateMachine:${NAME_PREFIX}-state-machine}"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") dry-run
  $(basename "$0") real-run
  $(basename "$0") status <execution-arn>
  $(basename "$0") history <execution-arn>
  $(basename "$0") describe

Optional env overrides:
  DR_REGION             (default: ${DR_REGION})
  ACCOUNT_ID            (default: ${ACCOUNT_ID})
  NAME_PREFIX           (default: ${NAME_PREFIX})
  TARGET_NODE_DESIRED   (default: ${TARGET_NODE_DESIRED})
  TARGET_REPLICAS       (default: ${TARGET_REPLICAS})
  STATE_MACHINE_ARN     (computed by default)
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing required command: $1" >&2
    exit 1
  }
}

start_execution() {
  local dry_run="$1"
  local run_tag="$2"
  local exec_name
  exec_name="dr-${run_tag}-$(date +%Y%m%d-%H%M%S)"

  aws stepfunctions start-execution \
    --region "${DR_REGION}" \
    --state-machine-arn "${STATE_MACHINE_ARN}" \
    --name "${exec_name}" \
    --input "{\"mode\":\"managed\",\"dry_run\":${dry_run},\"target_node_desired\":${TARGET_NODE_DESIRED},\"target_replicas\":${TARGET_REPLICAS}}"
}

describe_sm() {
  aws stepfunctions describe-state-machine \
    --region "${DR_REGION}" \
    --state-machine-arn "${STATE_MACHINE_ARN}" \
    --query '{name:name,stateMachineArn:stateMachineArn,status:status,type:type}'
}

status_exec() {
  local arn="$1"
  aws stepfunctions describe-execution \
    --region "${DR_REGION}" \
    --execution-arn "${arn}" \
    --query '{status:status,startDate:startDate,stopDate:stopDate,input:input,output:output}'
}

history_exec() {
  local arn="$1"
  aws stepfunctions get-execution-history \
    --region "${DR_REGION}" \
    --execution-arn "${arn}" \
    --max-results 50 \
    --reverse-order \
    --query 'events[*].[timestamp,type]' \
    --output table
}

main() {
  require_cmd aws

  local cmd="${1:-}"
  case "${cmd}" in
    dry-run)
      start_execution "true" "dryrun"
      ;;
    real-run)
      echo "WARNING: This is a destructive failover execution (dry_run=false)." >&2
      start_execution "false" "real"
      ;;
    status)
      [[ $# -eq 2 ]] || { usage; exit 1; }
      status_exec "$2"
      ;;
    history)
      [[ $# -eq 2 ]] || { usage; exit 1; }
      history_exec "$2"
      ;;
    describe)
      describe_sm
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
