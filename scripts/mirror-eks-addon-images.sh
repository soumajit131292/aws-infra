#!/usr/bin/env bash

set -euo pipefail

# Consolidated wrapper to mirror EKS add-on images to ECR for prod/prod-dr.
# Usage:
#   bash scripts/mirror-eks-addon-images.sh prod
#   bash scripts/mirror-eks-addon-images.sh prod-dr
#   bash scripts/mirror-eks-addon-images.sh both
#
# Optional overrides:
#   ACCOUNT_ID=495711089104 ECR_PREFIX=thirdparty SUFFIX=amd64-platform bash scripts/mirror-eks-addon-images.sh both

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_ENV="${1:-both}"

run_env() {
  local env="$1"
  local region="$2"
  local base_dir="$3"

  echo "=================================================="
  echo "Mirroring add-on images for ${env} (${region})"
  echo "Base dir: ${base_dir}"
  echo "=================================================="

  AWS_REGION="${region}" "${base_dir}/argocd/scripts/mirror-images-to-ecr.sh"
  AWS_REGION="${region}" "${base_dir}/external-secrets/scripts/mirror-eso-image-to-ecr.sh"
  AWS_REGION="${region}" "${base_dir}/grafana/scripts/mirror-images-to-ecr.sh"
  AWS_REGION="${region}" "${base_dir}/node-monitoring/scripts/mirror-images-to-ecr.sh"
  AWS_REGION="${region}" "${base_dir}/velero/scripts/mirror-images-to-ecr.sh"
}

case "${TARGET_ENV}" in
  prod)
    run_env "prod" "eu-west-1" "${ROOT_DIR}/envs/prod/eu-west-1/eks-add-on"
    ;;
  prod-dr)
    run_env "prod-dr" "eu-central-1" "${ROOT_DIR}/envs/prod-dr/eu-central-1/eks-add-on"
    ;;
  both)
    run_env "prod" "eu-west-1" "${ROOT_DIR}/envs/prod/eu-west-1/eks-add-on"
    run_env "prod-dr" "eu-central-1" "${ROOT_DIR}/envs/prod-dr/eu-central-1/eks-add-on"
    ;;
  *)
    echo "Invalid environment: ${TARGET_ENV}"
    echo "Valid values: prod | prod-dr | both"
    exit 1
    ;;
esac

echo "=================================================="
echo "Completed image mirroring for: ${TARGET_ENV}"
echo "=================================================="
