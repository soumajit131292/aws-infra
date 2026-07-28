region                       = "eu-west-1"
finding_publishing_frequency = "SIX_HOURS"

# Foundational (VPC Flow Logs, DNS, CloudTrail) is always on with the detector.
enable_eks_audit_logs   = true
enable_rds_login_events = true

# Runtime Monitoring: per node vCPU/month standing cost (~$1.50/vCPU).
# Enabled for prod. Set to false if you want to defer this cost.
enable_runtime_monitoring   = true
enable_eks_addon_management = true

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
}
