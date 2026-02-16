output "helm_release_name" {
  description = "External Secrets Helm release name"
  value       = module.external_secrets.helm_release_name
}

output "helm_release_namespace" {
  description = "Namespace where External Secrets is installed"
  value       = module.external_secrets.helm_release_namespace
}

output "helm_release_status" {
  description = "Helm release status"
  value       = module.external_secrets.helm_release_status
}

output "helm_release_version" {
  description = "Deployed External Secrets chart version"
  value       = module.external_secrets.helm_release_version
}

output "irsa_role_arn" {
  description = "IAM role ARN assumed by External Secrets via IRSA"
  value       = aws_iam_role.external_secrets_irsa.arn
}

output "cluster_secret_store_name" {
  description = "Default ClusterSecretStore name for AWS Secrets Manager"
  value       = var.create_cluster_secret_store ? var.cluster_secret_store_name : null
}
