variable "domain_name" {
  description = "Primary FQDN the certificate is issued for (e.g., prod-aws.accesshub-identity.com)."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional FQDNs to include as SANs on the same certificate."
  type        = list(string)
  default     = []
}

variable "key_algorithm" {
  description = "Public key algorithm. ForceNew on change. Allowed: RSA_2048, EC_prime256v1, EC_secp384r1."
  type        = string
  default     = "RSA_2048"

  validation {
    condition     = contains(["RSA_2048", "EC_prime256v1", "EC_secp384r1"], var.key_algorithm)
    error_message = "key_algorithm must be one of: RSA_2048, EC_prime256v1, EC_secp384r1."
  }
}

variable "hosted_zone_name" {
  description = "Route53 public hosted zone name (e.g., accesshub-identity.com). Must already exist in this account."
  type        = string
}

variable "validation_record_ttl" {
  description = "TTL in seconds for the DNS validation CNAME records."
  type        = number
  default     = 60
}

variable "wait_for_validation" {
  description = "If true, apply blocks until ACM marks the certificate ISSUED. Set false for fire-and-forget."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
