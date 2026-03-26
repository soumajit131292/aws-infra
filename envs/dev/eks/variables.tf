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

variable "enable_spot_runner_node_group" {
  description = "Enable dedicated SPOT node group for GitHub runners."
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
