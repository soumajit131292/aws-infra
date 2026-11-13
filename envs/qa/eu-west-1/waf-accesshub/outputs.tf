output "web_acl_arn" {
  description = "ARN of the QA WAF Web ACL (use in alb.ingress.kubernetes.io/wafv2-acl-arn)."
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_id" {
  description = "ID of the QA WAF Web ACL."
  value       = aws_wafv2_web_acl.this.id
}

output "log_group_name" {
  description = "CloudWatch log group receiving QA WAF logs."
  value       = aws_cloudwatch_log_group.waf.name
}
