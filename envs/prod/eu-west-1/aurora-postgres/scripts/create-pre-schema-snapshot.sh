#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") --cluster-id <db-cluster-id> --change-id <ticket-or-tag> [--region <aws-region>] [--wait]

Example:
  $(basename "$0") --cluster-id prod-aurora-postgres --change-id CHG-1234 --region eu-west-1 --wait
USAGE
}

CLUSTER_ID=""
CHANGE_ID=""
REGION="eu-west-1"
WAIT_FOR_AVAILABLE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cluster-id)
      CLUSTER_ID="${2:-}"
      shift 2
      ;;
    --change-id)
      CHANGE_ID="${2:-}"
      shift 2
      ;;
    --region)
      REGION="${2:-}"
      shift 2
      ;;
    --wait)
      WAIT_FOR_AVAILABLE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$CLUSTER_ID" || -z "$CHANGE_ID" ]]; then
  echo "--cluster-id and --change-id are required." >&2
  usage
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is required but not found." >&2
  exit 1
fi

# Keep identifier RDS-safe: lowercase letters, numbers, and hyphens.
SAFE_CHANGE_ID="$(echo "$CHANGE_ID" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-//; s/-$//')"
TS="$(date -u +%Y%m%d-%H%M%S)"
SNAPSHOT_ID="${CLUSTER_ID}-pre-schema-${SAFE_CHANGE_ID}-${TS}"

# RDS snapshot identifier max length is 63.
SNAPSHOT_ID="${SNAPSHOT_ID:0:63}"
SNAPSHOT_ID="${SNAPSHOT_ID%-}"

echo "Creating DB cluster snapshot: ${SNAPSHOT_ID}"
aws rds create-db-cluster-snapshot \
  --region "$REGION" \
  --db-cluster-identifier "$CLUSTER_ID" \
  --db-cluster-snapshot-identifier "$SNAPSHOT_ID" \
  --tags "Key=purpose,Value=pre-schema-change" "Key=change-id,Value=${CHANGE_ID}"

echo
echo "Snapshot creation requested."
echo "Snapshot ID: ${SNAPSHOT_ID}"

echo
echo "Check status:"
echo "aws rds describe-db-cluster-snapshots --region ${REGION} --db-cluster-snapshot-identifier ${SNAPSHOT_ID} --query 'DBClusterSnapshots[0].Status' --output text"

if [[ "$WAIT_FOR_AVAILABLE" == "true" ]]; then
  echo
  echo "Waiting for snapshot to become available..."
  aws rds wait db-cluster-snapshot-available \
    --region "$REGION" \
    --db-cluster-snapshot-identifier "$SNAPSHOT_ID"
  echo "Snapshot is available: ${SNAPSHOT_ID}"
fi

echo
echo "Rollback reference (restore from snapshot):"
echo "aws rds restore-db-cluster-from-snapshot --region ${REGION} --db-cluster-identifier <new-cluster-id> --snapshot-identifier ${SNAPSHOT_ID} --engine aurora-postgresql"
