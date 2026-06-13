output "database_name" {
  description = "Glue/Athena database name."
  value       = aws_glue_catalog_database.this.name
}

output "table_name" {
  description = "Glue/Athena ALB access log table name."
  value       = aws_glue_catalog_table.alb_access_logs.name
}

output "workgroup_name" {
  description = "Athena workgroup name."
  value       = aws_athena_workgroup.this.name
}

output "alb_logs_location" {
  description = "S3 location queried by the ALB access log table."
  value       = local.alb_logs_location
}

output "athena_output_location" {
  description = "S3 location for Athena query results."
  value       = local.athena_output_location
}

output "reader_policy_arn" {
  description = "IAM policy ARN for users/roles that should query ALB logs."
  value       = try(aws_iam_policy.reader[0].arn, null)
}
