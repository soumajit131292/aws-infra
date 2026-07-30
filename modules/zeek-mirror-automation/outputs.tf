output "lambda_function_name" {
  description = "Name of the reconcile Lambda."
  value       = aws_lambda_function.this.function_name
}

output "lambda_role_arn" {
  description = "IAM role ARN assumed by the Lambda."
  value       = aws_iam_role.this.arn
}

output "node_state_rule_arn" {
  description = "EventBridge rule ARN for node state-change triggers."
  value       = aws_cloudwatch_event_rule.node_state_change.arn
}

output "sweep_rule_arn" {
  description = "EventBridge rule ARN for the scheduled reconcile sweep."
  value       = aws_cloudwatch_event_rule.scheduled_sweep.arn
}
