region = "eu-west-1"

domain_name               = "prod-aws.accesshub-identity.com"
subject_alternative_names = []
hosted_zone_name          = "accesshub-identity.com"
key_algorithm             = "RSA_2048"

# The original certificate is expired, so don't keep Terraform waiting for its
# aws_acm_certificate_validation resource to return to ISSUED. The replacement
# certificate is already ISSUED; its ARN is exposed directly while this is false.
wait_for_validation = false

# Parallel issuance for expired-certificate rotation. This does not replace or
# detach the current certificate; deploy the resulting ARN to all consumers first.
issue_replacement_certificate = true

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
  Component   = "acm-public-cert"
}
