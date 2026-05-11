variable "region" {
  description = "AWS region. Must match the ALB region this certificate will attach to."
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

variable "key_algorithm" {
  description = "Public key algorithm. RSA_2048 is the universal-compat default."
  type        = string
  default     = "RSA_2048"
}

variable "hosted_zone_name" {
  description = "Public hosted zone (apex domain) where DNS validation records are created."
  type        = string
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
