variable "name_prefix" {
  description = "Prefix for alarm/topic names (e.g. dev, prod, prod-dr)."
  type        = string
}

variable "db_instance_identifiers" {
  description = "Aurora/RDS DB instance identifiers to monitor (the CloudWatch DBInstanceIdentifier dimension). One set of read-I/O alarms is created per instance."
  type        = list(string)
}

variable "alert_email_subscribers" {
  description = "Email addresses subscribed to the alerts SNS topic (the 'appropriate personnel'). Each must confirm the subscription email once."
  type        = list(string)
  default     = []
}

variable "read_latency_threshold_seconds" {
  description = "Alarm when average ReadLatency exceeds this (seconds). Default 0.02 = 20 ms."
  type        = number
  default     = 0.02
}

variable "read_iops_threshold" {
  description = "Alarm when average ReadIOPS exceeds this. Sensible starting default; tune to each env's baseline."
  type        = number
  default     = 3000
}

variable "read_throughput_threshold_bytes" {
  description = "Alarm when average ReadThroughput exceeds this (bytes/sec). Default 50 MB/s. Tune per env."
  type        = number
  default     = 52428800
}

variable "cpu_utilization_threshold_percent" {
  description = "Alarm when average CPUUtilization exceeds this percent."
  type        = number
  default     = 80
}

variable "free_local_storage_threshold_bytes" {
  description = "Alarm when average FreeLocalStorage drops BELOW this (bytes). Default 5 GB. Tune to the instance class's local storage size."
  type        = number
  default     = 5368709120
}

variable "period_seconds" {
  description = "Metric period for each alarm (seconds)."
  type        = number
  default     = 300
}

variable "evaluation_periods" {
  description = "Consecutive periods that must breach before alarming."
  type        = number
  default     = 3
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
