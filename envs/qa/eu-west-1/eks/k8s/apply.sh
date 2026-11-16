#!/usr/bin/env bash
# Renders the QA EFS StorageClasses with the QA file system IDs (read from the
# QA EKS Terraform outputs) and applies them plus the PVCs to the QA cluster.
# Refuses to run against any cluster other than qa-accesshub-cluster, and
# refuses any file system that is not tagged for the QA cluster.
set -euo pipefail
cd "$(dirname "$0")"

ctx_cluster="$(kubectl config view --minify -o jsonpath='{.contexts[0].context.cluster}')"
case "$ctx_cluster" in
  *qa-accesshub-cluster) ;;
  *) echo "Current kubectl context is '$ctx_cluster', not the QA cluster. Run:"
     echo "  aws eks update-kubeconfig --region eu-west-1 --name qa-accesshub-cluster"
     exit 1 ;;
esac

APP_FS="${QA_EFS_ID:-$(terraform -chdir=.. output -raw efs_file_system_id)}"
LOGS_FS="${QA_EFS_LOGS_ID:-$(terraform -chdir=.. output -raw efs_logs_file_system_id)}"

for fs in "$APP_FS" "$LOGS_FS"; do
  name="$(aws efs describe-file-systems --region eu-west-1 --file-system-id "$fs" \
          --query 'FileSystems[0].Name' --output text)"
  case "$name" in
    qa-accesshub-cluster-*) echo "OK  $fs ($name)" ;;
    *) echo "REFUSING: $fs is '$name', not a QA cluster file system."; exit 1 ;;
  esac
done

kubectl create namespace accesshub --dry-run=client -o yaml | kubectl apply -f -
sed "s/REPLACE_WITH_QA_EFS_FILE_SYSTEM_ID/$APP_FS/" efs-storageclass.yaml | kubectl apply -f -
sed "s/REPLACE_WITH_QA_EFS_LOGS_FILE_SYSTEM_ID/$LOGS_FS/" efs-logs-storageclass.yaml | kubectl apply -f -
kubectl apply -f efs-pvc.yaml -f efs-logs-pvc.yaml
kubectl -n accesshub get pvc efs-claim efs-logs-claim
