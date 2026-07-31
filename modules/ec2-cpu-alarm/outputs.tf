output "sns_topic_arn" {
  description = "SNS topic the CPU alarms publish to."
  value       = aws_sns_topic.this.arn
}

output "alarm_names" {
  description = "CPU alarm names by instance."
  value       = { for k, a in aws_cloudwatch_metric_alarm.cpu : k => a.alarm_name }
}
