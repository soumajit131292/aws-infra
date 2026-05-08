output "namespace" {
  description = "Namespace where monitoring add-ons are installed."
  value       = module.node_monitoring.namespace
}

output "kube_state_metrics_status" {
  description = "Helm status of kube-state-metrics."
  value       = module.node_monitoring.kube_state_metrics_status
}

output "node_exporter_status" {
  description = "Helm status of node-exporter."
  value       = module.node_monitoring.node_exporter_status
}
