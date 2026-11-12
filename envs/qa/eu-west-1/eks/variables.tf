variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}

variable "core_node_instance_types" {
  description = "Core node group instance types (prod uses m6i.xlarge)."
  type        = list(string)
  default     = ["m6i.large"]
}

variable "enable_spot_runner_node_group" {
  description = "Enable dedicated SPOT node group for GitHub runners (runners live in prod/dev, not QA)."
  type        = bool
  default     = false
}

variable "cluster_log_retention_in_days" {
  description = "EKS control-plane log retention (days)."
  type        = number
  default     = 30
}

variable "enable_efs_backup" {
  description = "AWS Backup for the EKS EFS file system."
  type        = bool
  default     = false
}

variable "create_efs_logs_file_system" {
  description = "Create the region-local logs EFS file system."
  type        = bool
  default     = true
}

variable "spot_runner_instance_types" {
  description = "SPOT node group instance types (2 vCPU / 8 GiB: m6a.large)."
  type        = list(string)
  default     = ["m6a.large"]
}

variable "spot_runner_min_size" {
  description = "Minimum number of SPOT nodes."
  type        = number
  default     = 0
}

variable "spot_runner_desired_size" {
  description = "Desired number of SPOT nodes."
  type        = number
  default     = 1
}

variable "spot_runner_max_size" {
  description = "Maximum number of SPOT nodes."
  type        = number
  default     = 3
}

variable "spot_runner_taint_key" {
  description = "Taint key for SPOT runner nodes."
  type        = string
  default     = "workload"
}

variable "spot_runner_taint_value" {
  description = "Taint value for SPOT runner nodes."
  type        = string
  default     = "github-runners"
}

variable "enable_metrics_server_addon" {
  description = "Enable EKS managed metrics-server add-on."
  type        = bool
  default     = true
}

variable "metrics_server_addon_version" {
  description = "Optional managed add-on version for metrics-server."
  type        = string
  default     = ""
}
