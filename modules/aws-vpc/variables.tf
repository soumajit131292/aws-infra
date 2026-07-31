variable "region" {}
variable "cluster_name" {}
variable "name" {}
variable "vpc_cidr" {}
variable "azs" { type = list(string) }

variable "flow_log_retention_in_days" {
  description = "CloudWatch retention (days) for the VPC flow logs log group."
  type        = number
  default     = 7
}

variable "public_subnets" {
  type = map(string)
}

variable "private_app_subnets" {
  type = map(string)
}

variable "firewall_subnets" {
  type = map(string)
}

variable "enable_network_firewall" {
  description = "Enable AWS Network Firewall and route private app egress through firewall endpoints."
  type        = bool
  default     = true
}

variable "interface_vpc_endpoints" {
  description = "Interface VPC endpoints to create (service suffixes, e.g. ecr.api, sts, kms)."
  type        = list(string)
  default = [
    "eks",
    "sts",
    "ec2",
    "ecr.api",
    "ecr.dkr",
    "logs",
    "monitoring",
    "ec2messages",
    "ssmmessages",
    "ssm",
    "kms",
    "secretsmanager",
    "rds"
  ]
}

variable "enable_s3_gateway_endpoint" {
  description = "Whether to create S3 Gateway endpoint."
  type        = bool
  default     = true
}

variable "private_db_subnets" {
  type = map(string)
}

variable "tags" {
  type = map(string)
}
