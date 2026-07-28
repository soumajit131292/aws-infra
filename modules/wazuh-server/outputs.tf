output "instance_id" {
  description = "Wazuh server EC2 instance ID."
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP of the Wazuh server (use as WAZUH_MANAGER for agents)."
  value       = aws_instance.this.private_ip
}

output "primary_network_interface_id" {
  description = "Primary ENI ID of the Wazuh server."
  value       = aws_instance.this.primary_network_interface_id
}

output "security_group_id" {
  description = "Security group ID attached to the Wazuh server."
  value       = aws_security_group.this.id
}

output "dashboard_url" {
  description = "Wazuh dashboard URL (reachable from admin CIDRs)."
  value       = "https://${aws_instance.this.private_ip}"
}
