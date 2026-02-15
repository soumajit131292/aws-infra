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
