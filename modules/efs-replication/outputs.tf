output "source_file_system_arn" {
  description = "ARN of the source EFS in the source region."
  value       = aws_efs_replication_configuration.this.source_file_system_arn
}

output "destination_file_system_id" {
  description = "ID of the destination EFS auto-created by AWS Replication in the destination region."
  value       = aws_efs_replication_configuration.this.destination[0].file_system_id
}

output "destination_file_system_arn" {
  description = "ARN of the destination EFS (constructed from ID + region + account)."
  value = aws_efs_replication_configuration.this.destination[0].file_system_id == null ? null : format(
    "arn:aws:elasticfilesystem:%s:%s:file-system/%s",
    var.destination_region,
    split(":", aws_efs_replication_configuration.this.source_file_system_arn)[4],
    aws_efs_replication_configuration.this.destination[0].file_system_id,
  )
}

output "destination_status" {
  description = "Replication status of the destination."
  value       = aws_efs_replication_configuration.this.destination[0].status
}
