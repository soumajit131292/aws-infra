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

variable "private_app_subnets" {
  type = map(string)
}

variable "private_db_subnets" {
  type = map(string)
}

variable "tags" {
  type = map(string)
}
