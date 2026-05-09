#!/usr/bin/env bash

set -euo pipefail

# Runs all mirror scripts under envs/prod-dr/eu-central-1/eks-add-on/*/scripts.
#
# Usage:
#   chmod +x ./envs/prod-dr/eu-central-1/eks-add-on/scripts/run-all-mirror-images.sh
#   ./envs/prod-dr/eu-central-1/eks-add-on/scripts/run-all-mirror-images.sh
#
# Optional:
#   CONTINUE_ON_ERROR=true ./.../run-all-mirror-images.sh
#   DRY_RUN=true ./.../run-all-mirror-images.sh
#   AWS_REGION=eu-central-1 ACCOUNT_ID=495711089104 SUFFIX=amd64-platform ./.../run-all-mirror-images.sh

AWS_REGION="${AWS_REGION:-eu-central-1}"
export AWS_REGION

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTINUE_ON_ERROR="${CONTINUE_ON_ERROR:-false}"
DRY_RUN="${DRY_RUN:-false}"

mapfile -t scripts < <(
  find "${ROOT_DIR}" -mindepth 3 -maxdepth 3 -type f -path "*/scripts/*.sh" \
    ! -path "*/eks-add-on/scripts/*" | sort
)

if [[ ${#scripts[@]} -eq 0 ]]; then
  echo "No mirror scripts found under ${ROOT_DIR}"
  exit 1
fi

echo "Found ${#scripts[@]} script(s):"
for s in "${scripts[@]}"; do
  echo "  - ${s}"
done
echo

failed=()
for s in "${scripts[@]}"; do
  echo "=================================================="
  echo "Running: ${s}"
  echo "=================================================="

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[DRY RUN] bash ${s}"
    continue
  fi

  if bash "${s}"; then
    echo "SUCCESS: ${s}"
  else
    echo "FAILED: ${s}"
    failed+=("${s}")
    if [[ "${CONTINUE_ON_ERROR}" != "true" ]]; then
      echo "Stopping on first failure. Set CONTINUE_ON_ERROR=true to continue."
      break
    fi
  fi
  echo
done

echo
echo "==================== Summary ===================="
if [[ ${#failed[@]} -eq 0 ]]; then
  echo "All scripts completed successfully."
  exit 0
fi

echo "Failed scripts (${#failed[@]}):"
for s in "${failed[@]}"; do
  echo "  - ${s}"
done
exit 1
