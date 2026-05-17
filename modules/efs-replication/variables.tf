variable "source_file_system_id" {
  description = "ID of the EFS file system in the source region that will be replicated."
  type        = string
}

variable "destination_region" {
  description = "AWS region where the destination EFS will be auto-provisioned by AWS Replication."
  type        = string
}

variable "destination_kms_key_arn" {
  description = "ARN of the KMS CMK (in destination_region) used to encrypt the destination EFS. Leave null to use the AWS-managed key aws/elasticfilesystem."
  type        = string
  default     = null
}

variable "destination_availability_zone_name" {
  description = "If set (e.g., eu-central-1a), the destination EFS is created as One Zone. Leave null for Regional (recommended for DR)."
  type        = string
  default     = null
}
