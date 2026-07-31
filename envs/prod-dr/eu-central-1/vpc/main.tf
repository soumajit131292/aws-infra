provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

module "network" {
  source                     = "../../../../modules/aws-vpc"
  name                       = var.name
  vpc_cidr                   = var.vpc_cidr
  cluster_name               = var.cluster_name
  azs                        = var.azs
  flow_log_retention_in_days = 365 # CEEL: 365-day log retention
  region                     = var.region
  public_subnets             = var.public_subnets
  private_app_subnets        = var.private_app_subnets
  private_db_subnets         = var.private_db_subnets
  firewall_subnets           = var.firewall_subnets
  enable_network_firewall    = var.enable_network_firewall
  interface_vpc_endpoints    = var.interface_vpc_endpoints
  enable_s3_gateway_endpoint = var.enable_s3_gateway_endpoint
  tags                       = var.tags
}
