variable "region" {
  description = "Source AWS region (where the prod EFS lives)."
  type        = string
}

variable "destination_region" {
  description = "DR AWS region (where the replicated EFS will live)."
  type        = string
}

variable "destination_kms_key_alias" {
  description = "KMS alias for the dedicated CMK created in destination_region to encrypt the destination EFS."
  type        = string
}

variable "destination_kms_deletion_window_in_days" {
  description = "Deletion window for the destination KMS CMK."
  type        = number
  default     = 30
}

variable "destination_efs_name_tag" {
  description = "Name tag applied to destination-side resources (SG, KMS, mount targets)."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
