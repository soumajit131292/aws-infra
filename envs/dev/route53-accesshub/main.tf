data "aws_route53_zone" "public" {
  name         = var.hosted_zone_name
  private_zone = false
}

data "aws_lb" "accesshub" {
  name = var.alb_name
}

resource "aws_route53_record" "accesshub_a" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = data.aws_lb.accesshub.dns_name
    zone_id                = data.aws_lb.accesshub.zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

resource "aws_route53_record" "accesshub_aaaa" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = var.record_name
  type    = "AAAA"

  alias {
    name                   = data.aws_lb.accesshub.dns_name
    zone_id                = data.aws_lb.accesshub.zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}
