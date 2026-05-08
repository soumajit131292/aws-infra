# Velero (dev)

This stack installs Velero on EKS for Kubernetes resource backup and restore.

## What it creates

- Velero namespace + service account (IRSA)
- IAM role/policy for Velero (S3 + snapshot permissions)
- S3 bucket for backups (optional, can use existing bucket)
- S3 default encryption (SSE-S3) for managed bucket
- S3 lifecycle retention policy for managed bucket
- Helm release for Velero with AWS plugin
- Default daily Velero backup schedule (configurable)

## Apply

```bash
cd envs/dev/eks-add-on/velero
terraform init
terraform plan
terraform apply
```

## Mirror Images To ECR

```bash
chmod +x ./scripts/mirror-images-to-ecr.sh
./scripts/mirror-images-to-ecr.sh
```

Then update `terraform.tfvars` with the printed ECR values for:
- `velero_image_repository`
- `velero_image_tag`
- `velero_plugin_image`

By default this stack uses the local chart at `modules/eks-velero/velero` (`use_local_chart = true`).

## Retention and Schedule

- `backup_bucket_retention_days`: object retention in S3
- `backup_bucket_noncurrent_retention_days`: previous object version retention
- `enable_default_backup_schedule`: toggles default schedule
- `backup_schedule_cron`: cron for schedule (default `0 2 * * *`)
- `backup_schedule_ttl_hours`: backup TTL (default 720h = 30 days)

## Verify

```bash
kubectl get pods -n velero
kubectl get backupstoragelocation -n velero
```

## Example backup command

```bash
velero backup create dev-full-$(date +%Y%m%d-%H%M%S) --include-namespaces '*' --wait
```

## Example restore command

```bash
velero restore create --from-backup <backup-name>
```
