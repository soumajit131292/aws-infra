output "detector_id" {
  description = "GuardDuty detector ID."
  value       = module.guardduty.detector_id
}

output "detector_arn" {
  description = "GuardDuty detector ARN."
  value       = module.guardduty.detector_arn
}

output "features_enabled" {
  description = "GuardDuty feature name -> status."
  value       = module.guardduty.features_enabled
}
