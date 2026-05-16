output "source_file_system_id" {
  description = "ID of the prod (source) EFS being replicated."
  value       = local.source_efs_id
}

output "destination_file_system_id" {
  description = "ID of the prod-dr (destination) EFS auto-created by AWS Replication. Use this in the prod-dr StorageClass."
  value       = module.efs_replication.destination_file_system_id
}

output "destination_file_system_arn" {
  description = "ARN of the destination EFS."
  value       = module.efs_replication.destination_file_system_arn
}

output "destination_security_group_id" {
  description = "Security group attached to destination EFS mount targets in prod-dr."
  value       = aws_security_group.destination_efs.id
}

output "destination_kms_key_arn" {
  description = "KMS CMK encrypting the destination EFS."
  value       = aws_kms_key.dr_efs.arn
}

output "destination_kms_key_alias" {
  description = "KMS alias for the destination CMK."
  value       = aws_kms_alias.dr_efs.name
}

output "destination_status" {
  description = "Replication status of the destination."
  value       = module.efs_replication.destination_status
}

output "destination_mount_target_ids" {
  description = "Mount target IDs in the destination region (one per private app subnet)."
  value       = [for mt in aws_efs_mount_target.destination : mt.id]
}
