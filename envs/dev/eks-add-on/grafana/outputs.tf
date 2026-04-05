output "namespace" {
  description = "Namespace where Grafana is installed."
  value       = module.grafana.namespace
}

output "grafana_status" {
  description = "Helm status of Grafana release."
  value       = module.grafana.grafana_status
}

output "grafana_irsa_role_arn" {
  description = "IAM role ARN used by Grafana service account."
  value       = module.grafana.irsa_role_arn
}

output "grafana_amp_datasource_url" {
  description = "Configured AMP datasource URL in Grafana."
  value       = module.grafana.amp_datasource_url
}
