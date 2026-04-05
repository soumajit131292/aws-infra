output "namespace" {
  description = "Namespace where node monitoring add-ons are installed."
  value       = var.namespace
}

output "kube_state_metrics_status" {
  description = "Helm release status for kube-state-metrics."
  value       = helm_release.kube_state_metrics.status
}

output "node_exporter_status" {
  description = "Helm release status for node-exporter."
  value       = helm_release.node_exporter.status
}
