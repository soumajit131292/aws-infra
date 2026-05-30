output "state_machine_arn" {
  value = module.dr_failover.state_machine_arn
}

output "trigger_command_example" {
  description = "Copy-paste this to start a failover."
  value       = module.dr_failover.trigger_command_example
}

output "approval_api_url" {
  value = module.dr_failover.approval_api_url
}

output "sns_alerts_topic_arn" {
  value = module.dr_failover.sns_alerts_topic_arn
}

output "sns_approval_topic_arn" {
  value = module.dr_failover.sns_approval_topic_arn
}

output "sns_complete_topic_arn" {
  value = module.dr_failover.sns_complete_topic_arn
}

output "route53_health_check_id" {
  description = "Route 53 health check ID. Use this if Route 53 failover routing needs to reference it."
  value       = module.dr_failover.route53_health_check_id
}

output "argocd_webhook_url" {
  description = "URL ArgoCD Notifications POSTs to when a sync starts / completes."
  value       = module.dr_failover.argocd_webhook_url
}
output "dashboard_name" {
  description = "CloudWatch dashboard aggregating all DR signals."
  value       = module.dr_failover.dashboard_name
}

output "dashboard_url" {
  description = "Direct URL to the DR overview dashboard."
  value       = module.dr_failover.dashboard_url
}

output "composite_alarm_replication_arn" {
  description = "P1 composite alarm: Aurora AND EFS replication lag together."
  value       = module.dr_failover.composite_alarm_replication_arn
}

output "trigger_command_example_dry_run" {
  description = "Copy-paste this to start a safe dry-run failover."
  value       = module.dr_failover.trigger_command_example_dry_run
}