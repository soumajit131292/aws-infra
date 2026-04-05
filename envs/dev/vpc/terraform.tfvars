region       = "us-east-1"
name         = "dev-vpc"
cluster_name = "dev-accesshub-cluster"

vpc_cidr = "10.10.0.0/16"
azs      = ["us-east-1a", "us-east-1b"]

public_subnets = {
  a = "10.10.0.0/24"
  b = "10.10.1.0/24"
}

private_app_subnets = {
  a = "10.10.10.0/23"
  b = "10.10.12.0/23"
}

private_db_subnets = {
  a = "10.10.30.0/24"
  b = "10.10.31.0/24"
}

firewall_subnets = {
  a = "10.10.20.0/24"
  b = "10.10.21.0/24"
}

enable_network_firewall = false

tags = {
  env   = "dev"
  owner = "terraform-accesshub-platform"
}
