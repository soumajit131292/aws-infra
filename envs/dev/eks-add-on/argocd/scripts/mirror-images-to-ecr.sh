#!/usr/bin/env bash

set -euo pipefail

# Mirror third-party images to ECR with a custom suffix tag.
# Usage:
#   chmod +x ./envs/dev/eks-add-on/argocd/scripts/mirror-images-to-ecr.sh
#   ./envs/dev/eks-add-on/argocd/scripts/mirror-images-to-ecr.sh
#
# Optional overrides:
#   AWS_REGION=us-east-1 ACCOUNT_ID=123456789012 SUFFIX=amd64-platform ./mirror-images-to-ecr.sh

############################################
# CONFIG
############################################
AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-495711089104}"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_PREFIX="${ECR_PREFIX:-thirdparty}"

# Suffix appended to source tag.
SUFFIX="${SUFFIX:-amd64-platform}"

IMAGES=(
  "quay.io/argoproj/argocd:v3.3.0"
  "ghcr.io/dexidp/dex:v2.44.0"
  "redis:8.2.3-alpine"
  "haproxy:3.0.8-alpine"
)

############################################
# LOGIN TO ECR
############################################
echo "Logging into ECR registry ${ECR_REGISTRY}"
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

############################################
# PROCESS IMAGES
############################################
for IMAGE in "${IMAGES[@]}"; do
  echo "--------------------------------------------------"
  echo "Processing image: ${IMAGE}"

  IMAGE_NAME="$(echo "${IMAGE}" | awk -F'/' '{print $NF}')"
  REPO_NAME="$(echo "${IMAGE_NAME}" | awk -F':' '{print $1}')"
  ORIGINAL_TAG="$(echo "${IMAGE_NAME}" | awk -F':' '{print $2}')"

  NEW_TAG="${ORIGINAL_TAG}-${SUFFIX}"
  TARGET_REPO="${ECR_PREFIX}/${REPO_NAME}"
  TARGET_IMAGE="${ECR_REGISTRY}/${TARGET_REPO}:${NEW_TAG}"

  echo "Ensuring repository exists: ${TARGET_REPO}"
  if ! aws ecr describe-repositories \
        --repository-names "${TARGET_REPO}" \
        --region "${AWS_REGION}" >/dev/null 2>&1; then
    aws ecr create-repository \
      --repository-name "${TARGET_REPO}" \
      --region "${AWS_REGION}" >/dev/null
    echo "Repository created"
  else
    echo "Repository already exists"
  fi

  echo "Pulling linux/amd64 image"
  docker pull --platform linux/amd64 "${IMAGE}"

  echo "Tagging image as ${TARGET_IMAGE}"
  docker tag "${IMAGE}" "${TARGET_IMAGE}"

  echo "Pushing image"
  docker push "${TARGET_IMAGE}"

  echo "Verifying architecture"
  docker inspect "${TARGET_IMAGE}" --format '{{.Architecture}}'

  echo "Done: ${TARGET_IMAGE}"
done

echo "=================================================="
echo "All images pushed successfully"
echo "Use tags with suffix: ${SUFFIX}"
