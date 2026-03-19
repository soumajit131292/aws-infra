variable "region" {
  description = "AWS region."
  type        = string
}

variable "private_zone_name" {
  description = "Private Route 53 hosted zone name (must end with a dot), e.g. accesshub.internal."
  type        = string
}

variable "rds_writer_record_name" {
  description = "Primary writer CNAME record name, e.g. db-primary.accesshub.internal."
  type        = string
}

variable "rds_active_record_name" {
  description = "Stable app-facing DB CNAME name, e.g. db.accesshub.internal."
  type        = string
}

variable "create_reader_record" {
  description = "Whether to create a CNAME for Aurora reader endpoint."
  type        = bool
  default     = true
}

variable "rds_reader_record_name" {
  description = "Record name for Aurora reader endpoint, e.g. db-reader.accesshub.internal."
  type        = string
  default     = "db-reader.accesshub.internal"
}

variable "record_ttl" {
  description = "TTL for CNAME records."
  type        = number
  default     = 60
}

variable "create_dr_record" {
  description = "Whether to create DR CNAME record now."
  type        = bool
  default     = false
}

variable "rds_dr_record_name" {
  description = "DR writer CNAME name, e.g. db-dr.accesshub.internal."
  type        = string
  default     = "db-dr.accesshub.internal"
}

variable "rds_dr_endpoint" {
  description = "DR RDS endpoint target. Leave empty until DR exists."
  type        = string
  default     = ""
}

variable "route_active_to_dr" {
  description = "If true, the app-facing DB CNAME points to DR record."
  type        = bool
  default     = false
}
