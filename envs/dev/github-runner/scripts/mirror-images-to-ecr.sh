#!/usr/bin/env bash

set -euo pipefail

# Mirror GitHub Actions Runner Controller images to ECR with a custom suffix tag.
# Usage:
#   chmod +x ./envs/dev/github-runner/scripts/mirror-images-to-ecr.sh
#   ./envs/dev/github-runner/scripts/mirror-images-to-ecr.sh
#
# Optional overrides:
#   AWS_REGION=us-east-1 ACCOUNT_ID=123456789012 ECR_PREFIX=thirdparty SUFFIX=amd64-platform ./mirror-images-to-ecr.sh
#
# Add extra images (comma-separated):
#   EXTRA_IMAGES="ghcr.io/actions/actions-runner-controller:v0.10.1,alpine:3.20" ./mirror-images-to-ecr.sh

############################################
# CONFIG
############################################
AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-495711089104}"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_PREFIX="${ECR_PREFIX:-thirdparty}"
SUFFIX="${SUFFIX:-amd64-platform}"
PLATFORM="${PLATFORM:-linux/amd64}"

# Source images from modules/github-runners/actions-runner-controller/{Chart.yaml,values.yaml}
# and cluster-autoscaler chart default image.
IMAGES=(
  "summerwind/actions-runner-controller:v0.27.6"
  "summerwind/actions-runner:latest"
  "quay.io/brancz/kube-rbac-proxy:v0.13.1"
  "registry.k8s.io/autoscaling/cluster-autoscaler:v1.31.0"
)

if [[ -n "${EXTRA_IMAGES:-}" ]]; then
  IFS=',' read -r -a EXTRA_ARRAY <<< "${EXTRA_IMAGES}"
  for img in "${EXTRA_ARRAY[@]}"; do
    IMAGES+=("${img}")
  done
fi

############################################
# HELPERS
############################################
ensure_repo() {
  local repo="$1"
  if ! aws ecr describe-repositories \
    --repository-names "${repo}" \
    --region "${AWS_REGION}" >/dev/null 2>&1; then
    aws ecr create-repository \
      --repository-name "${repo}" \
      --region "${AWS_REGION}" >/dev/null
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

  echo "Pulling ${PLATFORM}"
  docker pull --platform "${PLATFORM}" "${image}"

  echo "Tagging"
  docker tag "${image}" "${target_image}"

  echo "Pushing"
  docker push "${target_image}"

  echo "Done"
}

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
  mirror_image "${IMAGE}"
done

echo "=================================================="
echo "All GitHub runner images mirrored successfully."
echo
echo "Suggested overrides:"
echo "  Controller image repo: ${ECR_REGISTRY}/${ECR_PREFIX}/actions-runner-controller"
echo "  Runner image repo:     ${ECR_REGISTRY}/${ECR_PREFIX}/actions-runner"
echo "  RBAC proxy image repo: ${ECR_REGISTRY}/${ECR_PREFIX}/kube-rbac-proxy"
echo "  Autoscaler image repo: ${ECR_REGISTRY}/${ECR_PREFIX}/cluster-autoscaler"
echo
echo "Remember to set matching tags with suffix: ${SUFFIX}"
