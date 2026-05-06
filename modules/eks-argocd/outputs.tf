output "helm_release_name" {
  description = "Argo CD Helm release name"
  value       = helm_release.argocd.name
}

output "helm_release_namespace" {
  description = "Namespace where Argo CD is installed"
  value       = helm_release.argocd.namespace
}

output "helm_release_status" {
  description = "Helm release status"
  value       = helm_release.argocd.status
}

output "helm_release_version" {
  description = "Deployed Argo CD chart version"
  value       = helm_release.argocd.version
}
