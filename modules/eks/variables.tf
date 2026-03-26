variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "private_app_sg_id" {
  type        = string
  description = "Security group ID for private app / Terraform runner"
}

variable "tags" {
  type = map(string)
}

variable "core_node_max_pods" {
  description = "Maximum number of pods scheduled per core node."
  type        = number
  default     = 110
}

variable "enable_prefix_delegation" {
  description = "Enable prefix delegation for the AWS VPC CNI."
  type        = bool
  default     = true
}

variable "warm_prefix_target" {
  description = "Number of free prefixes to keep warm per node for the AWS VPC CNI."
  type        = number
  default     = 1
}

variable "enable_efs_csi_driver" {
  description = "Enable EFS CSI driver add-on and create an EFS file system for workloads."
  type        = bool
  default     = true
}

variable "efs_encrypted" {
  description = "Whether to enable encryption at rest for EFS."
  type        = bool
  default     = true
}

variable "efs_performance_mode" {
  description = "Performance mode for EFS."
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "Throughput mode for EFS."
  type        = string
  default     = "bursting"
}

variable "enable_efs_backup" {
  description = "Enable AWS Backup for EFS file system created by this module."
  type        = bool
  default     = false
}

variable "efs_backup_schedule" {
  description = "Cron expression for AWS Backup schedule for EFS."
  type        = string
  default     = "cron(0 5 * * ? *)"
}

variable "efs_backup_retention_days" {
  description = "Retention in days for EFS backups in AWS Backup."
  type        = number
  default     = 30
}

variable "enable_spot_runner_node_group" {
  description = "Enable a dedicated SPOT EKS node group for GitHub runner workloads."
  type        = bool
  default     = true
}

variable "spot_runner_instance_types" {
  description = "Instance types for the SPOT runner node group (2 vCPU / 8 GiB recommended)."
  type        = list(string)
  default     = ["m6a.large"]
}

variable "spot_runner_min_size" {
  description = "Minimum size of the SPOT runner node group."
  type        = number
  default     = 0
}

variable "spot_runner_desired_size" {
  description = "Desired size of the SPOT runner node group."
  type        = number
  default     = 1
}

variable "spot_runner_max_size" {
  description = "Maximum size of the SPOT runner node group."
  type        = number
  default     = 3
}

variable "spot_runner_taint_key" {
  description = "Kubernetes taint key for the SPOT runner node group."
  type        = string
  default     = "workload"
}

variable "spot_runner_taint_value" {
  description = "Kubernetes taint value for the SPOT runner node group."
  type        = string
  default     = "github-runners"
}

variable "cluster_log_retention_in_days" {
  description = "CloudWatch log retention (days) for EKS control plane log group."
  type        = number
  default     = 7
}

variable "enable_cloudwatch_observability" {
  description = "Enable Amazon CloudWatch Observability EKS managed add-on."
  type        = bool
  default     = false
}
