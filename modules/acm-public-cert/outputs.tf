output "certificate_arn" {
  description = "ACM certificate ARN. When wait_for_validation=true, the value is gated on successful validation."
  value       = var.wait_for_validation ? aws_acm_certificate_validation.this[0].certificate_arn : aws_acm_certificate.this.arn
}

output "certificate_domain_name" {
  description = "Primary FQDN on the issued certificate."
  value       = aws_acm_certificate.this.domain_name
}

output "certificate_subject_alternative_names" {
  description = "SAN list on the issued certificate."
  value       = aws_acm_certificate.this.subject_alternative_names
}

output "validation_record_fqdns" {
  description = "FQDNs of the DNS validation CNAME records created in the hosted zone."
  value       = [for r in aws_route53_record.validation : r.fqdn]
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID resolved from hosted_zone_name."
  value       = data.aws_route53_zone.this.zone_id
}
