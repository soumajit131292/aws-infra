output "hosted_zone_id" {
  description = "Private Route 53 hosted zone ID used for RDS records."
  value       = aws_route53_zone.private.zone_id
}

output "private_zone_name_servers" {
  description = "Private hosted zone name servers (informational only)."
  value       = aws_route53_zone.private.name_servers
}

output "rds_writer_record_fqdn" {
  description = "FQDN created for primary Aurora writer endpoint."
  value       = aws_route53_record.rds_writer.fqdn
}

output "rds_active_record_fqdn" {
  description = "Stable app-facing DB CNAME FQDN."
  value       = aws_route53_record.rds_active.fqdn
}

output "rds_active_target_record_name" {
  description = "Current target record name used by stable DB CNAME."
  value       = local.active_target_record_name
}

output "rds_dr_record_fqdn" {
  description = "DR record FQDN, if DR endpoint is configured."
  value       = try(aws_route53_record.rds_dr[0].fqdn, null)
}

output "rds_reader_record_fqdn" {
  description = "FQDN created for Aurora reader endpoint, if enabled."
  value       = try(aws_route53_record.rds_reader[0].fqdn, null)
}

output "alb_record_fqdn" {
  description = "FQDN created for ingress ALB, if enabled."
  value       = try(aws_route53_record.ingress_alb[0].fqdn, null)
}
