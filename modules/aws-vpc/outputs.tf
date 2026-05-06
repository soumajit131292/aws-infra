output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_app_subnet_ids" {
  value = values(aws_subnet.private_app)[*].id
}

output "private_db_subnet_ids" {
  value = values(aws_subnet.private_db)[*].id
}

output "private_app_sg_id" {
  description = "Security group ID for private application / Terraform runner"
  value       = aws_security_group.app.id
}

output "private_db_sg_id" {
  description = "Security group ID for private DB resources"
  value       = aws_security_group.db.id
}

output "ec2_ssm_instance_profile_name" {
  description = "Instance profile name for EC2 SSM access"
  value       = aws_iam_instance_profile.ec2_ssm.name
}

output "ec2_ssm_role_arn" {
  description = "IAM role ARN attached to EC2 SSM instance profile"
  value       = aws_iam_role.ec2_ssm.arn
}
