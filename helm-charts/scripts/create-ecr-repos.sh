#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/create-ecr-repos.sh
#   ./scripts/create-ecr-repos.sh eu-west-1 eu-central-1
#
# Prereqs:
#   - aws cli configured
#   - permission for ecr:DescribeRepositories, ecr:CreateRepository,
#     ecr:PutImageTagMutability, ecr:PutImageScanningConfiguration

REGION_PROD="${1:-eu-west-1}"
REGION_PROD_DR="${2:-eu-central-1}"

REPOS=(
  "accesshub/adminsvc"
  "accesshub/apponbsvc"
  "accesshub/pgmodsvc"
  "accesshub/loginmodsvc"
  "accesshub/snowmodsvc"
  "accesshub/gatewaysvc"
  "accesshub/ahschedular"
  "accesshub/scimpersist"
  "accesshub/grcsoapws"
  "accesshub/antdui"
  "accesshub/db-migration"
  "accesshub/health-aggregator"
)

ensure_repo() {
  local region="$1"
  local repo="$2"

  if aws ecr describe-repositories --region "$region" --repository-names "$repo" >/dev/null 2>&1; then
    echo "[$region] exists: $repo"
  else
    echo "[$region] creating: $repo"
    aws ecr create-repository \
      --region "$region" \
      --repository-name "$repo" \
      --image-tag-mutability MUTABLE \
      --image-scanning-configuration scanOnPush=true \
      >/dev/null
    echo "[$region] created: $repo"
  fi
}

for region in "$REGION_PROD" "$REGION_PROD_DR"; do
  echo "=== Processing region: $region ==="
  for repo in "${REPOS[@]}"; do
    ensure_repo "$region" "$repo"
  done
  echo
 done

echo "Done. ECR repository check/create completed for: $REGION_PROD, $REGION_PROD_DR"
