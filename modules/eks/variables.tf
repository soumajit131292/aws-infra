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
