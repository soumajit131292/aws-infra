#!/usr/bin/env bash

set -euo pipefail

# Mirror Grafana chart images to ECR with a custom suffix tag.
# Usage:
#   chmod +x ./envs/dev/eks-add-on/grafana/scripts/mirror-images-to-ecr.sh
#   ./envs/dev/eks-add-on/grafana/scripts/mirror-images-to-ecr.sh
#
# Optional overrides:
#   AWS_REGION=us-east-1 ACCOUNT_ID=123456789012 ECR_PREFIX=thirdparty SUFFIX=amd64-platform ./mirror-images-to-ecr.sh

AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-495711089104}"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_PREFIX="${ECR_PREFIX:-thirdparty}"
SUFFIX="${SUFFIX:-amd64-platform}"

IMAGES=(
  "docker.io/grafana/grafana:12.3.1"
  "docker.io/library/busybox:1.31.1"
)

echo "Logging into ECR registry ${ECR_REGISTRY}"
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

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
echo "Use these values in envs/dev/eks-add-on/grafana/terraform.tfvars:"
echo "grafana_image_registry     = \"${ECR_REGISTRY}\""
echo "grafana_image_repository   = \"${ECR_PREFIX}/grafana\""
echo "grafana_image_tag          = \"12.3.1-${SUFFIX}\""
echo "init_chown_image_registry  = \"${ECR_REGISTRY}\""
echo "init_chown_image_repository = \"${ECR_PREFIX}/busybox\""
echo "init_chown_image_tag       = \"1.31.1-${SUFFIX}\""
