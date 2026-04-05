output "namespace" {
  description = "Namespace where Grafana is installed."
  value       = module.grafana.namespace
}

output "grafana_status" {
  description = "Helm status of Grafana release."
  value       = module.grafana.grafana_status
}
