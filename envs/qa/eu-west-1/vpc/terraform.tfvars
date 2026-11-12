region       = "eu-west-1"
name         = "qa-eu-west-1-vpc"
cluster_name = "qa-accesshub-cluster"

# 10.40/16 — no overlap with dev 10.10, prod 10.20, prod-dr 10.30.
vpc_cidr = "10.40.0.0/16"
azs      = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

public_subnets = {
  a = "10.40.0.0/24"
  b = "10.40.1.0/24"
  c = "10.40.2.0/24"
}

private_app_subnets = {
  a = "10.40.10.0/23"
  b = "10.40.12.0/23"
  c = "10.40.14.0/23"
}

private_db_subnets = {
  a = "10.40.30.0/24"
  b = "10.40.31.0/24"
  c = "10.40.32.0/24"
}

# Unused while enable_network_firewall = false; kept so the layout matches prod.
firewall_subnets = {
  a = "10.40.20.0/24"
  b = "10.40.21.0/24"
  c = "10.40.22.0/24"
}

enable_network_firewall = false

# QA: one NAT gateway for all AZs (prod has one per AZ).
single_nat_gateway = true

interface_vpc_endpoints = [
  "ecr.api",
  "ecr.dkr",
  "sts",
  "secretsmanager",
  "kms"
]

enable_s3_gateway_endpoint = true

tags = {
  env   = "qa"
  owner = "terraform-accesshub-platform"
}
