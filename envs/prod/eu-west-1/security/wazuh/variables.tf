variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "alert_email_subscribers" {
  description = "Emails alerted on server CPU breaches (reused from the dr-failover list)."
  type        = list(string)
  default     = []
}

variable "cpu_threshold_percent" {
  description = "CPUUtilization alarm threshold (percent) for the Wazuh VM."
  type        = number
  default     = 80
}

variable "vpc_cidr" {
  description = "VPC CIDR (used to scope agent ingress). Must match the prod VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "instance_type" {
  description = "Wazuh server instance type (memory-optimized for OpenSearch)."
  type        = string
  default     = "r6i.large"
}

variable "root_volume_size" {
  description = "Root EBS volume size (GB)."
  type        = number
  default     = 50
}

variable "data_volume_size" {
  description = "Indexer (OpenSearch) data volume size (GB)."
  type        = number
  default     = 100
}

variable "admin_cidrs" {
  description = "Trusted admin CIDRs for dashboard (443) + SSH (22). MUST be set to your bastion/VPN ranges."
  type        = list(string)
  default     = []
}

variable "wazuh_version" {
  description = "Wazuh installer version series."
  type        = string
  default     = "4.9"
}

variable "retention_days" {
  description = "Days to retain Wazuh indices (ISM policy deletes older indices)."
  type        = number
  default     = 21
}

variable "enable_logall_json" {
  description = "Store all received events in Wazuh archives JSON, including raw Zeek events that do not raise alerts."
  type        = bool
  default     = false
}

variable "enable_archive_indexing" {
  description = "Index Wazuh archives into wazuh-archives-* so raw Zeek logs are searchable in the dashboard."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
