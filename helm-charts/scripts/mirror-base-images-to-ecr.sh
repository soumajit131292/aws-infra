#!/usr/bin/env bash
set -euo pipefail

# Mirror base images used by this repository Dockerfiles to ECR with suffix tags.
# Usage:
#   chmod +x scripts/mirror-base-images-to-ecr.sh
#   scripts/mirror-base-images-to-ecr.sh
# Optional overrides:
#   AWS_REGION=us-east-1 ACCOUNT_ID=495711089104 ECR_PREFIX=thirdparty SUFFIX=amd64-platform PLATFORM=linux/amd64 scripts/mirror-base-images-to-ecr.sh
#   EXTRA_IMAGES="alpine:3.20" scripts/mirror-base-images-to-ecr.sh

AWS_REGION="${AWS_REGION:-eu-central-1}"
ACCOUNT_ID="${ACCOUNT_ID:-495711089104}"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_PREFIX="${ECR_PREFIX:-thirdparty}"
SUFFIX="${SUFFIX:-amd64-platform}"
PLATFORM="${PLATFORM:-linux/amd64}"

IMAGES=(
  "maven:3.9.9-eclipse-temurin-11"
  "eclipse-temurin:11-jre"
  "node:20-alpine"
  "nginx:alpine"
  "flyway/flyway:10.17.1"
)

if [[ -n "${EXTRA_IMAGES:-}" ]]; then
  IFS=',' read -r -a EXTRA_ARRAY <<< "${EXTRA_IMAGES}"
  for img in "${EXTRA_ARRAY[@]}"; do
    IMAGES+=("${img}")
  done
fi

ensure_repo() {
  local repo="$1"
  if ! aws ecr describe-repositories --repository-names "${repo}" --region "${AWS_REGION}" >/dev/null 2>&1; then
    aws ecr create-repository --repository-name "${repo}" --region "${AWS_REGION}" >/dev/null
    echo "Repository created: ${repo}"
  else
    echo "Repository exists:  ${repo}"
  fi
}

mirror_image() {
  local image="$1"
  local image_name repo_name original_tag

  image_name="$(echo "${image}" | awk -F'/' '{print $NF}')"
  repo_name="$(echo "${image_name}" | awk -F':' '{print $1}')"
  original_tag="$(echo "${image_name}" | awk -F':' '{print $2}')"

  if [[ -z "${original_tag}" ]]; then
    original_tag="latest"
    image="${image}:latest"
  fi

  local new_tag target_repo target_image
  new_tag="${original_tag}-${SUFFIX}"
  target_repo="${ECR_PREFIX}/${repo_name}"
  target_image="${ECR_REGISTRY}/${target_repo}:${new_tag}"

  echo "--------------------------------------------------"
  echo "Source image : ${image}"
  echo "Target image : ${target_image}"

  ensure_repo "${target_repo}"

  docker pull --platform "${PLATFORM}" "${image}"
  docker tag "${image}" "${target_image}"
  docker push "${target_image}"

  echo "Done"
}

echo "Logging into ECR registry ${ECR_REGISTRY}"
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

for IMAGE in "${IMAGES[@]}"; do
  mirror_image "${IMAGE}"
done

echo "=================================================="
echo "All base images mirrored successfully."
echo "Maven:           ${ECR_REGISTRY}/${ECR_PREFIX}/maven:3.9.9-eclipse-temurin-11-${SUFFIX}"
echo "Temurin JRE:     ${ECR_REGISTRY}/${ECR_PREFIX}/eclipse-temurin:11-jre-${SUFFIX}"
echo "Node:            ${ECR_REGISTRY}/${ECR_PREFIX}/node:20-alpine-${SUFFIX}"
echo "Nginx:           ${ECR_REGISTRY}/${ECR_PREFIX}/nginx:alpine-${SUFFIX}"
echo "Flyway:          ${ECR_REGISTRY}/${ECR_PREFIX}/flyway:10.17.1-${SUFFIX}"
