output "hosted_zone_id" {
  description = "Private Route 53 hosted zone ID used for RDS records."
  value       = module.route53_rds_private.hosted_zone_id
}

output "private_zone_name_servers" {
  description = "Private hosted zone name servers (informational only)."
  value       = module.route53_rds_private.private_zone_name_servers
}

output "rds_writer_record_fqdn" {
  description = "FQDN created for primary Aurora writer endpoint."
  value       = module.route53_rds_private.rds_writer_record_fqdn
}

output "rds_active_record_fqdn" {
  description = "Stable app-facing DB CNAME FQDN."
  value       = module.route53_rds_private.rds_active_record_fqdn
}

output "rds_active_target_record_name" {
  description = "Current target record name used by stable DB CNAME."
  value       = module.route53_rds_private.rds_active_target_record_name
}

output "rds_writer_target" {
  description = "Primary Aurora writer endpoint targeted by CNAME."
  value       = data.terraform_remote_state.aurora.outputs.cluster_endpoint
}

output "rds_reader_record_fqdn" {
  description = "FQDN created for Aurora reader endpoint, if enabled."
  value       = module.route53_rds_private.rds_reader_record_fqdn
}

output "rds_reader_target" {
  description = "Aurora reader endpoint targeted by CNAME."
  value       = data.terraform_remote_state.aurora.outputs.reader_endpoint
}

output "rds_dr_record_fqdn" {
  description = "DR record FQDN, if DR endpoint is configured."
  value       = module.route53_rds_private.rds_dr_record_fqdn
}

output "alb_record_fqdn" {
  description = "FQDN created for ingress ALB, if enabled."
  value       = module.route53_rds_private.alb_record_fqdn
}

output "public_alb_record_fqdn" {
  description = "PUBLIC FQDN created for ingress ALB, if enabled."
  value       = try(aws_route53_record.public_ingress_alb[0].fqdn, null)
}
