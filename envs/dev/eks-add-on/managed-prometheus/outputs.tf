output "workspace_arn" {
  description = "AMP workspace ARN used by scraper."
  value       = local.workspace_arn
}

output "workspace_id" {
  description = "AMP workspace ID."
  value       = try(aws_prometheus_workspace.this[0].workspace_id, split("/", local.workspace_arn)[1], null)
}

output "scraper_id" {
  description = "Managed scraper ID."
  value       = aws_prometheus_scraper.eks.scraper_id
}

output "scraper_status" {
  description = "Managed scraper status."
  value       = aws_prometheus_scraper.eks.status
}
