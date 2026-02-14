variable "thumbprint_list" {
  description = "GitHub OIDC thumbprints"
  type        = list(string)

  default = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

variable "tags" {
  description = "Tags for OIDC provider"
  type        = map(string)
  default     = {}
}
