variable "region" {
  description = "AWS region. Must match the ALB region this certificate will attach to (eu-central-1 for prod-dr)."
  type        = string
}

variable "domain_name" {
  description = "Primary FQDN for the certificate."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional FQDNs to include as SANs on the same certificate."
  type        = list(string)
  default     = []
}

variable "hosted_zone_name" {
  description = "Public hosted zone (apex domain) where DNS validation records are created. Must exist in this AWS account."
  type        = string
}

variable "key_algorithm" {
  description = "Public key algorithm. RSA_2048 is the universal-compat default."
  type        = string
  default     = "RSA_2048"
}

variable "wait_for_validation" {
  description = "If true, apply blocks until ACM marks the certificate ISSUED."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
