output "detector_id" {
  description = "GuardDuty detector ID (account + region scoped)."
  value       = aws_guardduty_detector.this.id
}

output "detector_arn" {
  description = "GuardDuty detector ARN."
  value       = aws_guardduty_detector.this.arn
}

output "features_enabled" {
  description = "Map of GuardDuty feature name -> status as configured by this module."
  value = {
    (aws_guardduty_detector_feature.eks_audit_logs.name)     = aws_guardduty_detector_feature.eks_audit_logs.status
    (aws_guardduty_detector_feature.runtime_monitoring.name) = aws_guardduty_detector_feature.runtime_monitoring.status
    (aws_guardduty_detector_feature.rds_login_events.name)   = aws_guardduty_detector_feature.rds_login_events.status
  }
}
