output "instance_id" {
  description = "Zeek sensor EC2 instance ID."
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP of the Zeek sensor."
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "Security group ID attached to the sensor."
  value       = aws_security_group.this.id
}

output "traffic_mirror_target_id" {
  description = "Traffic mirror target ID (the sensor ENI)."
  value       = aws_ec2_traffic_mirror_target.this.id
}

output "traffic_mirror_filter_id" {
  description = "Traffic mirror filter ID."
  value       = aws_ec2_traffic_mirror_filter.this.id
}

output "mirror_session_ids" {
  description = "Map of source-ENI slot -> traffic mirror session ID."
  value       = { for k, s in aws_ec2_traffic_mirror_session.this : k => s.id }
}
