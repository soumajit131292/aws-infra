output "certificate_arn" {
  description = "ACM certificate ARN for prod-aws.accesshub-identity.com."
  value       = module.acm_public_cert.certificate_arn
}

output "certificate_domain_name" {
  description = "Primary FQDN on the issued certificate."
  value       = module.acm_public_cert.certificate_domain_name
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID where validation records were placed."
  value       = module.acm_public_cert.hosted_zone_id
}
