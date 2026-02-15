output "helm_release_name" {
  description = "External Secrets Helm release name"
  value       = helm_release.external_secrets.name
}

output "helm_release_namespace" {
  description = "Namespace where External Secrets is installed"
  value       = helm_release.external_secrets.namespace
}

output "helm_release_status" {
  description = "Helm release status"
  value       = helm_release.external_secrets.status
}

output "helm_release_version" {
  description = "Deployed External Secrets chart version"
  value       = helm_release.external_secrets.version
}
