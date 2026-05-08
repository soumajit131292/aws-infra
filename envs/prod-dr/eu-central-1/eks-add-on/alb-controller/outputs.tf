output "alb_access_logs_bucket_name" {
  description = "S3 bucket name used for ALB access logs"
  value       = local.alb_access_logs_bucket_name_effective
}

output "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  value       = local.alb_access_logs_prefix_effective
}

output "alb_ingress_load_balancer_attributes_annotation" {
  description = "Ingress annotation value for alb.ingress.kubernetes.io/load-balancer-attributes"
  value       = local.alb_access_logs_annotation
}
