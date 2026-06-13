output "database_name" {
  description = "Glue/Athena database name."
  value       = module.alb_log_athena.database_name
}

output "table_name" {
  description = "Glue/Athena ALB access log table name."
  value       = module.alb_log_athena.table_name
}

output "workgroup_name" {
  description = "Athena workgroup name."
  value       = module.alb_log_athena.workgroup_name
}

output "alb_logs_location" {
  description = "S3 location queried by the ALB access log table."
  value       = module.alb_log_athena.alb_logs_location
}

output "athena_output_location" {
  description = "S3 location for Athena query results."
  value       = module.alb_log_athena.athena_output_location
}

output "reader_policy_arn" {
  description = "IAM policy ARN for users/roles that should query ALB logs."
  value       = module.alb_log_athena.reader_policy_arn
}
