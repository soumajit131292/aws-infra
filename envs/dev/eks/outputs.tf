############################
# EKS root module outputs
############################

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate (base64)"
  value       = module.eks.cluster_ca_certificate
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL"
  value       = module.eks.oidc_issuer_url
}

output "alb_controller_role_arn" {
  description = "IAM role ARN used by AWS Load Balancer Controller"
  value       = module.eks.alb_controller_role_arn
}