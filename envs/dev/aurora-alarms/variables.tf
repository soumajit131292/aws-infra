variable "region" {
  description = "AWS region (must match the dev Aurora cluster)."
  type        = string
  default     = "us-east-1"
}

variable "cluster_identifier" {
  description = "Dev Aurora cluster identifier."
  type        = string
  default     = "dev-aurora-postgres"
}

variable "alert_email_subscribers" {
  description = "Emails alerted on read-I/O breaches (reused from the dr-failover list)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
