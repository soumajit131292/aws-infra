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
}
