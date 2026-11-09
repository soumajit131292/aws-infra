output "namespace" {
  description = "Namespace where the Wazuh agent is installed."
  value       = module.wazuh_agent.helm_release_namespace
}

output "helm_release_status" {
  description = "Helm status of the Wazuh agent release."
  value       = module.wazuh_agent.helm_release_status
}
