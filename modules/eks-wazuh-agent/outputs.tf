output "helm_release_name" {
  description = "Wazuh agent Helm release name"
  value       = helm_release.wazuh_agent.name
}

output "helm_release_namespace" {
  description = "Namespace where the Wazuh agent is installed"
  value       = helm_release.wazuh_agent.namespace
}

output "helm_release_status" {
  description = "Helm release status"
  value       = helm_release.wazuh_agent.status
}
