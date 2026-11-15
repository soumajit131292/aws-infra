output "repository_prefix" {
  description = "QA repository namespace."
  value       = var.repository_prefix
}

output "repository_urls" {
  description = "Repository URL per service."
  value       = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}
