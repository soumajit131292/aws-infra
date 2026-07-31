output "sns_topic_arn" {
  description = "SNS topic that the DB alarms publish to."
  value       = module.rds_alarms.sns_topic_arn
}

output "read_latency_alarm_names" {
  value = module.rds_alarms.read_latency_alarm_names
}

output "read_iops_alarm_names" {
  value = module.rds_alarms.read_iops_alarm_names
}

output "read_throughput_alarm_names" {
  value = module.rds_alarms.read_throughput_alarm_names
}

output "cpu_alarm_names" {
  value = module.rds_alarms.cpu_alarm_names
}

output "free_storage_alarm_names" {
  value = module.rds_alarms.free_storage_alarm_names
}
