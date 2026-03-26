output "backup_bucket_name" {
  description = "S3 bucket used by Velero backups"
  value       = local.backup_bucket_name_effective
}

output "velero_irsa_role_arn" {
  description = "IAM role ARN used by Velero via IRSA"
  value       = aws_iam_role.velero_irsa.arn
}

output "velero_release_status" {
  description = "Velero Helm release status"
  value       = module.velero_helm.release_status
}
