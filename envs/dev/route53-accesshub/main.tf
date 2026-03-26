data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "network/vpc/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "aurora" {
  backend = "s3"
  config = {
    bucket = "crave-infra-terraform-state-bucket"
    key    = "database/aurora-postgres/terraform.tfstate"
    region = var.region
  }
}

data "aws_lb" "ingress" {
  count = var.create_alb_record && length(trimspace(var.alb_dns_name)) == 0 && length(trimspace(var.alb_name)) > 0 ? 1 : 0
  name  = var.alb_name
}

locals {
  resolved_alb_dns_name        = length(trimspace(var.alb_dns_name)) > 0 ? var.alb_dns_name : try(data.aws_lb.ingress[0].dns_name, "")
  resolved_alb_zone_id         = length(trimspace(var.alb_zone_id)) > 0 ? var.alb_zone_id : try(data.aws_lb.ingress[0].zone_id, "")
  resolved_rds_writer_endpoint = var.use_rds_proxy_endpoint && length(trimspace(try(data.terraform_remote_state.aurora.outputs.rds_proxy_endpoint, ""))) > 0 ? data.terraform_remote_state.aurora.outputs.rds_proxy_endpoint : data.terraform_remote_state.aurora.outputs.cluster_endpoint
}

module "route53_rds_private" {
  source = "../../../modules/route53-rds-private"

  private_zone_name = var.private_zone_name
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id

  rds_writer_endpoint = local.resolved_rds_writer_endpoint
  rds_reader_endpoint = data.terraform_remote_state.aurora.outputs.reader_endpoint

  rds_writer_record_name = var.rds_writer_record_name
  rds_active_record_name = var.rds_active_record_name
  create_reader_record   = var.create_reader_record
  rds_reader_record_name = var.rds_reader_record_name
  record_ttl             = var.record_ttl

  create_dr_record   = var.create_dr_record
  rds_dr_record_name = var.rds_dr_record_name
  rds_dr_endpoint    = var.rds_dr_endpoint
  route_active_to_dr = var.route_active_to_dr

  create_alb_record = var.create_alb_record
  alb_record_name   = var.alb_record_name
  alb_dns_name      = local.resolved_alb_dns_name
}
