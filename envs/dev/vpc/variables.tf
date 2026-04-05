variable "region" {}
variable "cluster_name" {}
variable "name" {}
variable "vpc_cidr" {}
variable "azs" { type = list(string) }

variable "public_subnets" {
  type = map(string)
}

variable "firewall_subnets" {
  type = map(string)
}

variable "enable_network_firewall" {
  description = "Enable AWS Network Firewall for VPC egress inspection."
  type        = bool
  default     = false
}

variable "interface_vpc_endpoints" {
  description = "Interface VPC endpoints to create."
  type        = list(string)
  default = [
    "ecr.api",
    "ecr.dkr",
    "sts",
    "secretsmanager",
    "kms"
  ]
}

variable "enable_s3_gateway_endpoint" {
  description = "Whether to create S3 Gateway endpoint."
  type        = bool
  default     = true
}

variable "private_app_subnets" {
  type = map(string)
}

variable "private_db_subnets" {
  type = map(string)
}

variable "tags" {
  type = map(string)
}
