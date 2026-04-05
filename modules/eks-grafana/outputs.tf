output "namespace" {
  description = "Namespace where Grafana is installed."
  value       = var.namespace
}

output "grafana_status" {
  description = "Helm release status for Grafana."
  value       = helm_release.grafana.status
}

output "irsa_role_arn" {
  description = "Grafana IRSA role ARN."
  value       = try(aws_iam_role.grafana_irsa[0].arn, null)
}

output "amp_datasource_url" {
  description = "Configured AMP datasource URL in Grafana."
  value       = local.amp_datasource_url
}
