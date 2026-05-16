output "global_cluster_identifier" {
  description = "Aurora Global Cluster identifier. Secondary clusters set their global_cluster_identifier to this."
  value       = aws_rds_global_cluster.this.global_cluster_identifier
}

output "global_cluster_arn" {
  description = "ARN of the Aurora Global Cluster."
  value       = aws_rds_global_cluster.this.arn
}

output "global_cluster_resource_id" {
  description = "AWS resource ID of the Aurora Global Cluster."
  value       = aws_rds_global_cluster.this.global_cluster_resource_id
}

output "engine" {
  description = "Engine inherited from the adopted primary cluster."
  value       = aws_rds_global_cluster.this.engine
}

output "engine_version" {
  description = "Engine version inherited from the adopted primary cluster."
  value       = aws_rds_global_cluster.this.engine_version
}

output "database_name" {
  description = "Database name inherited from the adopted primary cluster."
  value       = aws_rds_global_cluster.this.database_name
}
