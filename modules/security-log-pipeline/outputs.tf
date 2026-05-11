output "bucket_name" {
  description = "Security logs S3 bucket name."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "Security logs S3 bucket ARN."
  value       = aws_s3_bucket.this.arn
}

output "kms_key_arn" {
  description = "KMS CMK ARN protecting the security log archive."
  value       = aws_kms_key.this.arn
}

output "kms_key_id" {
  description = "KMS CMK ID."
  value       = aws_kms_key.this.key_id
}

output "firehose_stream_arns" {
  description = "Map of subscription key -> Firehose delivery stream ARN."
  value       = { for k, v in aws_kinesis_firehose_delivery_stream.this : k => v.arn }
}

output "firehose_stream_names" {
  description = "Map of subscription key -> Firehose delivery stream name."
  value       = { for k, v in aws_kinesis_firehose_delivery_stream.this : k => v.name }
}

output "firehose_role_arn" {
  description = "IAM role ARN assumed by Firehose."
  value       = aws_iam_role.firehose.arn
}

output "cwlogs_to_firehose_role_arn" {
  description = "IAM role ARN used by CloudWatch Logs subscription filters."
  value       = aws_iam_role.cwlogs_to_firehose.arn
}
