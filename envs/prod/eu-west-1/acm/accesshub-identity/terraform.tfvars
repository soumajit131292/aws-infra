region = "eu-west-1"

domain_name               = "prod-aws.accesshub-identity.com"
subject_alternative_names = []
hosted_zone_name          = "accesshub-identity.com"
key_algorithm             = "RSA_2048"

wait_for_validation = true

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
  Component   = "acm-public-cert"
}
