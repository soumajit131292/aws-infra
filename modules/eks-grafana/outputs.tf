output "namespace" {
  description = "Namespace where Grafana is installed."
  value       = var.namespace
}

output "grafana_status" {
  description = "Helm release status for Grafana."
  value       = helm_release.grafana.status
}
