module "acm_public_cert" {
  source = "../../../../../modules/acm-public-cert"

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  hosted_zone_name          = var.hosted_zone_name
  key_algorithm             = var.key_algorithm
  wait_for_validation       = var.wait_for_validation

  tags = var.tags
}
