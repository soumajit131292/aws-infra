output "helm_release_name" {
  description = "Argo CD Helm release name"
  value       = module.argocd.helm_release_name
}

output "helm_release_namespace" {
  description = "Namespace where Argo CD is installed"
  value       = module.argocd.helm_release_namespace
}

output "helm_release_status" {
  description = "Helm release status"
  value       = module.argocd.helm_release_status
}

output "helm_release_version" {
  description = "Deployed Argo CD chart version"
  value       = module.argocd.helm_release_version
}
