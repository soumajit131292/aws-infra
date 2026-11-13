region = "eu-west-1"

domain_name               = "qa.accesshub-identity.com"
subject_alternative_names = []

# The public zone is shared at the account level; the cert and its validation
# record are QA's own (unique _<hash>.qa.accesshub-identity.com name).
hosted_zone_name = "accesshub-identity.com"
key_algorithm    = "RSA_2048"

wait_for_validation = true

tags = {
  Environment = "qa"
  Project     = "crave"
  ManagedBy   = "terraform"
  Component   = "acm-public-cert"
}
