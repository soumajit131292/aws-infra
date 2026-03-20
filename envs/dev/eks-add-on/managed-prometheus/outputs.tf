output "workspace_arn" {
  description = "AMP workspace ARN used by scraper."
  value       = local.workspace_arn
}

output "workspace_id" {
  description = "AMP workspace ID."
  value       = try(aws_prometheus_workspace.this[0].id, null)
}

output "scraper_id" {
  description = "Managed scraper resource ID."
  value       = aws_prometheus_scraper.eks.id
}

output "scraper_arn" {
  description = "Managed scraper ARN."
  value       = aws_prometheus_scraper.eks.arn
}
