##############################################################################
## Amazon GuardDuty detector + feature toggles
##
## The detector itself turns on the FOUNDATIONAL sources at no per-feature
## cost decision: VPC Flow Logs, DNS query logs, and CloudTrail management
## events. GuardDuty ingests these natively from the AWS control plane -- it
## does NOT read the CloudWatch flow logs this account already ships, and no
## CloudTrail trail is required for foundational coverage.
##
## Everything beyond foundational is opt-in via aws_guardduty_detector_feature:
##   - EKS_AUDIT_LOGS      -> Kubernetes audit-log threat detection (cheap)
##   - RUNTIME_MONITORING  -> in-cluster agent, priced per node vCPU (cost driver)
##   - RDS_LOGIN_EVENTS    -> Aurora/RDS login anomaly + brute-force detection
##############################################################################

resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  tags = var.tags
}

########################################
## EKS Protection (Kubernetes audit)  ##
########################################
resource "aws_guardduty_detector_feature" "eks_audit_logs" {
  detector_id = aws_guardduty_detector.this.id
  name        = "EKS_AUDIT_LOGS"
  status      = var.enable_eks_audit_logs ? "ENABLED" : "DISABLED"
}

#################################################################
## EKS Runtime Monitoring (in-cluster agent) -- THE COST DRIVER ##
##
## Billed per node vCPU/month, NOT per traffic. With the current
## core node group (m6i.xlarge = 4 vCPU per app subnet) this scales
## with node count, so it is DISABLED by default -- flip it on per env.
##
## EKS_ADDON_MANAGEMENT lets GuardDuty install/patch the
## aws-guardduty-agent EKS add-on automatically. The nodes need egress
## to the GuardDuty data endpoint (existing NAT egress is sufficient;
## a VPC endpoint also works).
#################################################################
resource "aws_guardduty_detector_feature" "runtime_monitoring" {
  detector_id = aws_guardduty_detector.this.id
  name        = "RUNTIME_MONITORING"
  status      = var.enable_runtime_monitoring ? "ENABLED" : "DISABLED"

  additional_configuration {
    name   = "EKS_ADDON_MANAGEMENT"
    status = var.enable_runtime_monitoring && var.enable_eks_addon_management ? "ENABLED" : "DISABLED"
  }
}

########################################
## RDS Protection (Aurora PostgreSQL) ##
########################################
resource "aws_guardduty_detector_feature" "rds_login_events" {
  detector_id = aws_guardduty_detector.this.id
  name        = "RDS_LOGIN_EVENTS"
  status      = var.enable_rds_login_events ? "ENABLED" : "DISABLED"
}
