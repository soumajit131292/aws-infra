variable "name_prefix" {
  description = "Prefix for the SNS topic name (e.g. prod-wazuh)."
  type        = string
}

variable "instances" {
  description = "Map of instance name -> EC2 instance ID to create a CPU alarm for."
  type        = map(string)
}

variable "cpu_threshold_percent" {
  description = "Alarm when average CPUUtilization exceeds this percent."
  type        = number
  default     = 80
}

variable "period_seconds" {
  description = "Metric period (seconds)."
  type        = number
  default     = 300
}

variable "evaluation_periods" {
  description = "Consecutive breaching periods before alarming."
  type        = number
  default     = 3
}

variable "alert_email_subscribers" {
  description = "Email addresses subscribed to the alerts SNS topic. Each must confirm once."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
