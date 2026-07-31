variable "region" {
  description = "AWS region (must match the prod-dr Aurora cluster)."
  type        = string
  default     = "eu-central-1"
}

variable "cluster_identifier" {
  description = "Prod-DR Aurora cluster identifier."
  type        = string
  default     = "prod-dr-aurora-postgres"
}

variable "alert_email_subscribers" {
  description = "Emails alerted on breaches (reused from the dr-failover list)."
  type        = list(string)
  default     = []
}

variable "cpu_utilization_threshold_percent" {
  description = "CPUUtilization alarm threshold (percent)."
  type        = number
  default     = 80
}

variable "read_iops_threshold" {
  description = "ReadIOPS alarm threshold."
  type        = number
  default     = 8000
}

variable "read_throughput_threshold_bytes" {
  description = "ReadThroughput alarm threshold (bytes/sec). Default 100 MB/s."
  type        = number
  default     = 104857600
}

variable "free_local_storage_threshold_bytes" {
  description = "FreeLocalStorage low-water alarm (bytes). Default 10 GB."
  type        = number
  default     = 10737418240
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
