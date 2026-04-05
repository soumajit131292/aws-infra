variable "region" {}
variable "cluster_name" {}
variable "name" {}
variable "vpc_cidr" {}
variable "azs" { type = list(string) }

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

variable "private_db_subnets" {
  type = map(string)
}

variable "tags" {
  type = map(string)
}
