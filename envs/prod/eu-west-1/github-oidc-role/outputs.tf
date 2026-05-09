output "github_actions_role_arn" {
  description = "IAM role ARN assumed by GitHub Actions"
  value       = module.github_actions_role.role_arn
}
