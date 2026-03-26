# Velero (dev)

This stack installs Velero on EKS for Kubernetes resource backup and restore.

## What it creates

- Velero namespace + service account (IRSA)
- IAM role/policy for Velero (S3 + snapshot permissions)
- S3 bucket for backups (optional, can use existing bucket)
- Helm release for Velero with AWS plugin

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
