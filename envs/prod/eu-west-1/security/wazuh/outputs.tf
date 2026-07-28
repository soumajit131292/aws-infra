output "wazuh_private_ip" {
  description = "Wazuh manager private IP (WAZUH_MANAGER for agents)."
  value       = module.wazuh.private_ip
}

output "wazuh_instance_id" {
  description = "Wazuh server EC2 instance ID (for SSM Session Manager)."
  value       = module.wazuh.instance_id
}

output "wazuh_security_group_id" {
  description = "Wazuh server security group ID."
  value       = module.wazuh.security_group_id
}

output "wazuh_dashboard_url" {
  description = "Wazuh dashboard URL."
  value       = module.wazuh.dashboard_url
}
