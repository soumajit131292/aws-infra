output "cluster_id" {
  description = "Aurora cluster ID"
  value       = module.aurora_postgres.cluster_id
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = module.aurora_postgres.cluster_arn
}

output "cluster_endpoint" {
  description = "Writer endpoint"
  value       = module.aurora_postgres.cluster_endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint"
  value       = module.aurora_postgres.reader_endpoint
}

output "security_group_id" {
  description = "Aurora security group ID"
  value       = module.aurora_postgres.security_group_id
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = module.aurora_postgres.db_subnet_group_name
}
