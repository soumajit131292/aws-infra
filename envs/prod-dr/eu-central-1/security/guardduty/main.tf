#############################################
# GuardDuty — prod DR (eu-central-1)
#
# Detector is account + region scoped: this stack
# covers the account within eu-central-1, independent
# of the primary prod detector in eu-west-1.
#############################################
module "guardduty" {
  source = "../../../../../modules/guardduty"

  finding_publishing_frequency = var.finding_publishing_frequency

  enable_eks_audit_logs       = var.enable_eks_audit_logs
  enable_runtime_monitoring   = var.enable_runtime_monitoring
  enable_eks_addon_management = var.enable_eks_addon_management
  enable_rds_login_events     = var.enable_rds_login_events

  tags = var.tags
}
