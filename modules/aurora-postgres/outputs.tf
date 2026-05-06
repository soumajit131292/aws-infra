output "cluster_id" {
  description = "Aurora cluster ID"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = aws_rds_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "Database port"
  value       = aws_rds_cluster.this.port
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.this.name
}

output "security_group_id" {
  description = "Aurora security group ID"
  value       = aws_security_group.aurora.id
}

output "instance_ids" {
  description = "Aurora instance identifiers"
  value       = aws_rds_cluster_instance.this[*].id
}

output "rds_proxy_name" {
  description = "RDS Proxy name, if enabled."
  value       = try(aws_db_proxy.this[0].name, null)
}

output "rds_proxy_arn" {
  description = "RDS Proxy ARN, if enabled."
  value       = try(aws_db_proxy.this[0].arn, null)
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint, if enabled."
  value       = try(aws_db_proxy.this[0].endpoint, null)
}

output "rds_proxy_security_group_id" {
  description = "RDS Proxy security group ID, if enabled."
  value       = try(aws_security_group.rds_proxy[0].id, null)
}
