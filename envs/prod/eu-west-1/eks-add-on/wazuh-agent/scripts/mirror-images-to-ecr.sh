#!/usr/bin/env bash

set -euo pipefail

# Mirror the Wazuh agent image to ECR with a custom suffix tag.
# Usage:
#   chmod +x ./envs/prod/eu-west-1/eks-add-on/wazuh-agent/scripts/mirror-images-to-ecr.sh
#   ./envs/prod/eu-west-1/eks-add-on/wazuh-agent/scripts/mirror-images-to-ecr.sh
#
# Optional overrides:
#   AWS_REGION=eu-west-1 ACCOUNT_ID=123456789012 ECR_PREFIX=thirdparty SUFFIX=amd64-platform ./mirror-images-to-ecr.sh
#
# The agent version must not be newer than the Wazuh manager. Check the
# manager with: sudo /var/ossec/bin/wazuh-control info

AWS_REGION="${AWS_REGION:-eu-west-1}"
ACCOUNT_ID="${ACCOUNT_ID:-495711089104}"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_PREFIX="${ECR_PREFIX:-thirdparty}"
SUFFIX="${SUFFIX:-amd64-platform}"

IMAGES=(
  "docker.io/wazuh/wazuh-agent:4.14.10"
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

  # The chart overrides the entrypoint with /bin/sh /config/start.sh and
  # expects a standard /var/ossec agent install inside the image.
  echo "Checking image layout"
  docker run --rm --platform linux/amd64 --entrypoint /bin/sh "${IMAGE}" -c \
    'test -x /var/ossec/bin/wazuh-control && /var/ossec/bin/wazuh-control info'

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
echo "Use these values in envs/prod/eu-west-1/eks-add-on/wazuh-agent/terraform.tfvars:"
echo "image_registry   = \"${ECR_REGISTRY}\""
echo "image_repository = \"${ECR_PREFIX}/wazuh-agent\""
echo "image_tag        = \"4.14.10-${SUFFIX}\""
