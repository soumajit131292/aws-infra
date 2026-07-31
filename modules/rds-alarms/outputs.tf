output "sns_topic_arn" {
  description = "SNS topic ARN alerts are published to."
  value       = aws_sns_topic.this.arn
}

output "read_latency_alarm_names" {
  description = "ReadLatency alarm names by instance."
  value       = { for k, a in aws_cloudwatch_metric_alarm.read_latency : k => a.alarm_name }
}

output "read_iops_alarm_names" {
  description = "ReadIOPS alarm names by instance."
  value       = { for k, a in aws_cloudwatch_metric_alarm.read_iops : k => a.alarm_name }
}

output "read_throughput_alarm_names" {
  description = "ReadThroughput alarm names by instance."
  value       = { for k, a in aws_cloudwatch_metric_alarm.read_throughput : k => a.alarm_name }
}

output "cpu_alarm_names" {
  description = "CPUUtilization alarm names by instance."
  value       = { for k, a in aws_cloudwatch_metric_alarm.cpu : k => a.alarm_name }
}

output "free_storage_alarm_names" {
  description = "FreeLocalStorage alarm names by instance."
  value       = { for k, a in aws_cloudwatch_metric_alarm.free_local_storage : k => a.alarm_name }
}
