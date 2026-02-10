output "iam_role_arn" {
  description = "IAM role ARN used by ALB controller"
  value       = aws_iam_role.alb_controller.arn
}

output "helm_release_status" {
  description = "Helm release status"
  value       = helm_release.alb_controller.status
}
