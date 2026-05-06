region       = "eu-west-1"
name         = "prod-eu-west-1-vpc"
cluster_name = "prod-accesshub-cluster"

vpc_cidr = "10.20.0.0/16"
azs      = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

public_subnets = {
  a = "10.20.0.0/24"
  b = "10.20.1.0/24"
  c = "10.20.2.0/24"
}

private_app_subnets = {
  a = "10.20.10.0/23"
  b = "10.20.12.0/23"
  c = "10.20.14.0/23"
}

private_db_subnets = {
  a = "10.20.30.0/24"
  b = "10.20.31.0/24"
  c = "10.20.32.0/24"
}

firewall_subnets = {
  a = "10.20.20.0/24"
  b = "10.20.21.0/24"
  c = "10.20.22.0/24"
}

enable_network_firewall = false

interface_vpc_endpoints = [
  "ecr.api",
  "ecr.dkr",
  "sts",
  "secretsmanager",
  "kms"
]

enable_s3_gateway_endpoint = true

tags = {
  env   = "prod"
  owner = "terraform-accesshub-platform"
}
