#!/usr/bin/env bash
set -euo pipefail

# Mirror health-aggregator base image to ECR.
# Usage:
#   chmod +x scripts/mirror-health-aggregator-base-to-ecr.sh
#   scripts/mirror-health-aggregator-base-to-ecr.sh
#
# Optional overrides:
#   AWS_REGION=us-east-1 ACCOUNT_ID=495711089104 ECR_REPO=accesshub/health-aggregator SUFFIX=amd64-platform PLATFORM=linux/amd64 \
#   scripts/mirror-health-aggregator-base-to-ecr.sh

AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-495711089104}"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPO="${ECR_REPO:-accesshub/health-aggregator}"
SOURCE_IMAGE="${SOURCE_IMAGE:-python:3.12-slim}"
SUFFIX="${SUFFIX:-amd64-platform}"
PLATFORM="${PLATFORM:-linux/amd64}"
TARGET_TAG="${TARGET_TAG:-python-3.12-slim-${SUFFIX}}"
TARGET_IMAGE="${ECR_REGISTRY}/${ECR_REPO}:${TARGET_TAG}"

ensure_repo() {
  if ! aws ecr describe-repositories --repository-names "${ECR_REPO}" --region "${AWS_REGION}" >/dev/null 2>&1; then
    aws ecr create-repository --repository-name "${ECR_REPO}" --region "${AWS_REGION}" >/dev/null
    echo "Repository created: ${ECR_REPO}"
  else
    echo "Repository exists:  ${ECR_REPO}"
  fi
}

echo "Logging into ECR registry ${ECR_REGISTRY}"
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

ensure_repo

echo "--------------------------------------------------"
echo "Source image : ${SOURCE_IMAGE}"
echo "Target image : ${TARGET_IMAGE}"
echo "Platform     : ${PLATFORM}"

docker pull --platform "${PLATFORM}" "${SOURCE_IMAGE}"
docker tag "${SOURCE_IMAGE}" "${TARGET_IMAGE}"
docker push "${TARGET_IMAGE}"

echo "=================================================="
echo "Health-aggregator base image mirrored successfully."
echo "Use this in Dockerfile:"
echo "  FROM ${TARGET_IMAGE}"
