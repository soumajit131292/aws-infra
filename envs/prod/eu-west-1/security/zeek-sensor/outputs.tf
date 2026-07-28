output "zeek_private_ip" {
  description = "Zeek sensor private IP."
  value       = module.zeek_sensor.private_ip
}

output "zeek_instance_id" {
  description = "Zeek sensor EC2 instance ID (for SSM Session Manager)."
  value       = module.zeek_sensor.instance_id
}

output "traffic_mirror_target_id" {
  description = "Traffic mirror target ID."
  value       = module.zeek_sensor.traffic_mirror_target_id
}

output "mirror_session_ids" {
  description = "Traffic mirror session IDs by source-ENI slot."
  value       = module.zeek_sensor.mirror_session_ids
}
