# Temporary blue/green certificate issuance. This deliberately leaves
# module.acm_public_cert (the currently attached/expired certificate) intact.
# The ACM DNS validation token is stable for this account/domain, so reuse the
# Route 53 validation CNAME managed by the existing module rather than creating
# a second Terraform owner for the same DNS record.
resource "aws_acm_certificate" "replacement" {
  count = var.issue_replacement_certificate ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
  key_algorithm             = var.key_algorithm

  tags = merge(var.tags, {
    Name   = "${var.domain_name}-replacement"
    Rotate = "true"
  })
}

resource "aws_acm_certificate_validation" "replacement" {
  count = var.issue_replacement_certificate && var.wait_for_validation ? 1 : 0

  certificate_arn         = aws_acm_certificate.replacement[0].arn
  validation_record_fqdns = module.acm_public_cert.validation_record_fqdns
}
