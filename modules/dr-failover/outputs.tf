output "state_machine_arn" {
  description = "ARN of the DR failover Step Functions state machine."
  value       = aws_sfn_state_machine.dr_failover.arn
}

output "state_machine_name" {
  description = "Name of the state machine — use with 'aws stepfunctions start-execution'."
  value       = aws_sfn_state_machine.dr_failover.name
}

output "approval_api_url" {
  description = "Base URL of the approval webhook (operator never calls this directly — clicks the SNS link)."
  value       = "${aws_apigatewayv2_api.approval.api_endpoint}/approve"
}

output "sns_alerts_topic_arn" {
  description = "Detection alerts topic in DR region (eu-central-1). Email subscribers receive notifications here."
  value       = aws_sns_topic.dr_alerts.arn
}

output "sns_approval_topic_arn" {
  description = "Approval-request topic — receives approve/deny URLs."
  value       = aws_sns_topic.dr_approval.arn
}

output "sns_complete_topic_arn" {
  description = "Completion notifications topic."
  value       = aws_sns_topic.dr_complete.arn
}

output "route53_health_check_id" {
  description = "Route 53 health check on the prod ALB endpoint."
  value       = aws_route53_health_check.prod_app.id
}

output "cloudwatch_alarm_arn" {
  description = "CloudWatch alarm watching the Route 53 health check."
  value       = aws_cloudwatch_metric_alarm.prod_app_unhealthy.arn
}

output "tier1_alarms" {
  description = "Map of all Tier-1 detection alarms by name -> ARN."
  value = {
    route53_unhealthy      = aws_cloudwatch_metric_alarm.prod_app_unhealthy.arn
    alb_unhealthy_hosts    = aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.arn
    alb_target_5xx_high    = aws_cloudwatch_metric_alarm.alb_target_5xx.arn
    aurora_replication_lag = aws_cloudwatch_metric_alarm.aurora_replication_lag.arn
    aurora_db_load_high    = aws_cloudwatch_metric_alarm.aurora_db_load_high.arn
    aurora_no_connections  = try(aws_cloudwatch_metric_alarm.aurora_no_connections[0].arn, null)
    efs_replication_lag    = aws_cloudwatch_metric_alarm.efs_replication_lag.arn
  }
}

output "aws_health_rule_arns" {
  description = "EventBridge rule ARNs that listen for AWS Health Dashboard events."
  value = {
    source = aws_cloudwatch_event_rule.aws_health_source.arn
    dr     = aws_cloudwatch_event_rule.aws_health_dr.arn
  }
}

output "argocd_webhook_url" {
  description = "URL to configure in ArgoCD Notifications service.webhook.cloudwatch-control.url"
  value       = "${aws_apigatewayv2_api.argocd_webhook.api_endpoint}/argocd-webhook"
}

output "alarm_suppression_state_table" {
  description = "DynamoDB table tracking deployment-in-progress state."
  value       = aws_dynamodb_table.alarm_suppression_state.name
}

output "alarm_suppression_lambda_name" {
  description = "Lambda function that disables/enables alarm actions."
  value       = aws_lambda_function.alarm_actions_controller.function_name
}

output "sns_alerts_topic_arns_by_region" {
  description = "Map of dr-alerts SNS topic ARNs by region."
  value = {
    "${var.dr_region}"     = aws_sns_topic.dr_alerts.arn
    "${var.source_region}" = aws_sns_topic.dr_alerts_source.arn
    "us-east-1"            = aws_sns_topic.dr_alerts_us_east_1.arn
  }
}

output "composite_alarm_replication_arn" {
  description = "P1 composite alarm — fires when Aurora AND EFS replication both lag (cross-region degradation leading indicator)."
  value       = aws_cloudwatch_composite_alarm.cross_region_replication_degraded.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard with all DR signals on one page."
  value       = aws_cloudwatch_dashboard.dr_overview.dashboard_name
}

output "dashboard_url" {
  description = "Direct URL to the DR overview dashboard."
  value       = "https://${var.dr_region}.console.aws.amazon.com/cloudwatch/home?region=${var.dr_region}#dashboards:name=${aws_cloudwatch_dashboard.dr_overview.dashboard_name}"
}

output "lambda_arns" {
  description = "Map of Lambda function ARNs by step name."
  value       = { for k, l in aws_lambda_function.lambdas : k => l.arn }
}

output "trigger_command_example" {
  description = "Example AWS CLI command to start a REAL failover execution (destructive — promotes Aurora, deletes EFS replication, flips DNS, scales EKS)."
  value       = <<-EOT
    aws stepfunctions start-execution \\
      --region ${var.dr_region} \\
      --state-machine-arn ${aws_sfn_state_machine.dr_failover.arn} \\
      --input '{"mode":"managed","dry_run":false,"target_node_desired":${var.target_node_desired},"target_replicas":${var.target_app_replicas}}'
  EOT
}

output "trigger_command_example_dry_run" {
  description = "Example AWS CLI command to start a DRY-RUN execution. Exercises the full state machine, sends approval email, but does NOT promote Aurora / delete EFS replication / flip DNS / scale EKS. Safe to run monthly in production."
  value       = <<-EOT
    aws stepfunctions start-execution \
      --region ${var.dr_region} \
      --state-machine-arn ${aws_sfn_state_machine.dr_failover.arn} \
      --name "dr-dryrun-$(date +%Y%m%d-%H%M%S)" \
      --input '{"mode":"managed","dry_run":true,"target_node_desired":${var.target_node_desired},"target_replicas":${var.target_app_replicas}}'
  EOT
}
