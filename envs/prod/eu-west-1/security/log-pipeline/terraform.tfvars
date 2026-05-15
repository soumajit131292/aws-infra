region      = "eu-west-1"
name_prefix = "prod"

# Globally unique. Override if "crave-central-security-logs-prod" is taken.
bucket_name   = "crave-central-security-logs-prod"
kms_key_alias = "alias/prod-security-logs"

# Which CloudWatch log groups to ship.
ship_application = true
ship_audit       = true
ship_host        = false
ship_dataplane   = false

# Optional: set to your ingress controller log group name to enable.
ingress_log_group_name = ""

# Namespace allowlist for `application` (pod) logs.
include_namespaces = ["accesshub"]

# Firehose buffering — 128 MB / 300 s as recommended.
firehose_buffer_size_mb          = 128
firehose_buffer_interval_seconds = 300
firehose_compression_format      = "GZIP"

# S3 lifecycle.
lifecycle_ia_days           = 30
lifecycle_glacier_days      = 90
lifecycle_deep_archive_days = 180
lifecycle_expiration_days   = 2555

# IRREVERSIBLE once true. Leave false until you're ready to commit.
object_lock_enabled = false

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
  Component   = "security-log-pipeline"
}
