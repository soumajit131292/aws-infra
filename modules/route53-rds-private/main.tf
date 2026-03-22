locals {
  active_target_record_name = var.route_active_to_dr ? var.rds_dr_record_name : var.rds_writer_record_name
}

resource "aws_route53_zone" "private" {
  name = var.private_zone_name

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "rds_writer" {
  zone_id = aws_route53_zone.private.zone_id
  name    = var.rds_writer_record_name
  type    = "CNAME"
  ttl     = var.record_ttl
  records = [var.rds_writer_endpoint]
}

resource "aws_route53_record" "rds_active" {
  zone_id = aws_route53_zone.private.zone_id
  name    = var.rds_active_record_name
  type    = "CNAME"
  ttl     = var.record_ttl
  records = [local.active_target_record_name]

  lifecycle {
    precondition {
      condition     = !var.route_active_to_dr || (var.create_dr_record && length(trimspace(var.rds_dr_endpoint)) > 0)
      error_message = "route_active_to_dr=true requires create_dr_record=true and non-empty rds_dr_endpoint."
    }
  }
}

resource "aws_route53_record" "rds_reader" {
  count = var.create_reader_record ? 1 : 0

  zone_id = aws_route53_zone.private.zone_id
  name    = var.rds_reader_record_name
  type    = "CNAME"
  ttl     = var.record_ttl
  records = [var.rds_reader_endpoint]
}

resource "aws_route53_record" "rds_dr" {
  count = var.create_dr_record && length(trimspace(var.rds_dr_endpoint)) > 0 ? 1 : 0

  zone_id = aws_route53_zone.private.zone_id
  name    = var.rds_dr_record_name
  type    = "CNAME"
  ttl     = var.record_ttl
  records = [var.rds_dr_endpoint]
}

resource "aws_route53_record" "ingress_alb" {
  count = var.create_alb_record && length(trimspace(var.alb_dns_name)) > 0 ? 1 : 0

  zone_id = aws_route53_zone.private.zone_id
  name    = var.alb_record_name
  type    = "CNAME"
  ttl     = var.record_ttl
  records = [var.alb_dns_name]
}
