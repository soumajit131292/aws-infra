output "bucket_name" {
  description = "Security logs S3 bucket name."
  value       = module.security_log_pipeline.bucket_name
}

output "bucket_arn" {
  description = "Security logs S3 bucket ARN."
  value       = module.security_log_pipeline.bucket_arn
}

output "kms_key_arn" {
  description = "KMS CMK ARN for the security log archive."
  value       = module.security_log_pipeline.kms_key_arn
}

output "firehose_stream_arns" {
  description = "Map of subscription key -> Firehose ARN."
  value       = module.security_log_pipeline.firehose_stream_arns
}
