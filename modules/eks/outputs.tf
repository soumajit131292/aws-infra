output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_issuer_url" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "alb_controller_role_arn" {
  description = "IAM role ARN used by AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "efs_file_system_id" {
  description = "EFS file system ID for Kubernetes persistent storage."
  value       = try(aws_efs_file_system.this[0].id, null)
}

output "efs_security_group_id" {
  description = "Security group ID attached to EFS mount targets."
  value       = try(aws_security_group.efs[0].id, null)
}

output "efs_logs_file_system_id" {
  description = "Region-local logs EFS file system ID. Null when create_efs_logs_file_system is false."
  value       = try(aws_efs_file_system.logs[0].id, null)
}

output "efs_logs_security_group_id" {
  description = "Security group ID attached to the logs EFS mount targets."
  value       = try(aws_security_group.efs_logs[0].id, null)
}
