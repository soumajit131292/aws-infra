region       = "eu-central-1"
name         = "prod-dr-eu-central-1-vpc"
cluster_name = "prod-dr-accesshub-cluster"

vpc_cidr = "10.30.0.0/16"
azs      = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

public_subnets = {
  a = "10.30.0.0/24"
  b = "10.30.1.0/24"
  c = "10.30.2.0/24"
}

private_app_subnets = {
  a = "10.30.10.0/23"
  b = "10.30.12.0/23"
  c = "10.30.14.0/23"
}

private_db_subnets = {
  a = "10.30.30.0/24"
  b = "10.30.31.0/24"
  c = "10.30.32.0/24"
}

firewall_subnets = {
  a = "10.30.20.0/24"
  b = "10.30.21.0/24"
  c = "10.30.22.0/24"
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
  env   = "prod-dr"
  owner = "terraform-accesshub-platform"
}
