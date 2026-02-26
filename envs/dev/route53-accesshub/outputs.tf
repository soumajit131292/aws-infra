output "hosted_zone_id" {
  description = "Route 53 hosted zone ID used for the record."
  value       = data.aws_route53_zone.public.zone_id
}

output "record_fqdn" {
  description = "FQDN created in Route 53."
  value       = aws_route53_record.accesshub_a.fqdn
}

output "alb_dns_name" {
  description = "ALB DNS name targeted by alias."
  value       = data.aws_lb.accesshub.dns_name
}
