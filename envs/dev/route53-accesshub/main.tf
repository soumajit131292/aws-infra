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
  count = (var.create_alb_record || var.create_public_alb_record) && length(trimspace(var.alb_dns_name)) == 0 && length(trimspace(var.alb_name)) > 0 ? 1 : 0
  name  = var.alb_name
}

locals {
  resolved_alb_dns_name   = length(trimspace(var.alb_dns_name)) > 0 ? var.alb_dns_name : try(data.aws_lb.ingress[0].dns_name, "")
  resolved_alb_zone_id    = length(trimspace(var.alb_zone_id)) > 0 ? var.alb_zone_id : try(data.aws_lb.ingress[0].zone_id, "")
  resolved_public_zone_id = length(trimspace(var.public_hosted_zone_id)) > 0 ? var.public_hosted_zone_id : try(data.aws_route53_zone.public[0].zone_id, "")
}

data "aws_route53_zone" "public" {
  count        = var.create_public_alb_record && length(trimspace(var.public_hosted_zone_id)) == 0 && length(trimspace(var.public_hosted_zone_name)) > 0 ? 1 : 0
  name         = var.public_hosted_zone_name
  private_zone = false
}

module "route53_rds_private" {
  source = "../../../modules/route53-rds-private"

  private_zone_name = var.private_zone_name
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id

  rds_writer_endpoint = data.terraform_remote_state.aurora.outputs.cluster_endpoint
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

resource "aws_route53_record" "public_ingress_alb" {
  count = var.create_public_alb_record && length(trimspace(local.resolved_public_zone_id)) > 0 && length(trimspace(var.public_alb_record_name)) > 0 && length(trimspace(local.resolved_alb_dns_name)) > 0 && length(trimspace(local.resolved_alb_zone_id)) > 0 ? 1 : 0

  zone_id = local.resolved_public_zone_id
  name    = var.public_alb_record_name
  type    = "A"

  alias {
    name                   = local.resolved_alb_dns_name
    zone_id                = local.resolved_alb_zone_id
    evaluate_target_health = true
  }
}
