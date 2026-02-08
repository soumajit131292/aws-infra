provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

module "network" {
  source = "../../../modules/aws-vpc"
  name     = var.name
  vpc_cidr = var.vpc_cidr
  cluster_name = var.cluster_name
  azs      = var.azs
  region= var.region
  public_subnets      = var.public_subnets
  private_app_subnets = var.private_app_subnets
  private_db_subnets  = var.private_db_subnets
  firewall_subnets    = var.firewall_subnets
  tags = var.tags
}
