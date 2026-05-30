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
