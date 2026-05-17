region = "eu-central-1"

# Pattern A (transparent DR) -- same FQDN as prod. On failover, Route53 record
# for this FQDN is flipped from prod ALB (eu-west-1) to prod-dr ALB (eu-central-1).
# Both ALBs have their own regional cert covering the same FQDN.
# Change to "prod-dr-aws.accesshub-identity.com" for a separate DR URL (Pattern B).
domain_name               = "prod-aws.accesshub-identity.com"
subject_alternative_names = []
hosted_zone_name          = "accesshub-identity.com"
key_algorithm             = "RSA_2048"

wait_for_validation = true

tags = {
  Environment = "prod-dr"
  Project     = "crave"
  ManagedBy   = "terraform"
  Component   = "acm-public-cert"
}
