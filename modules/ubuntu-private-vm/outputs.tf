output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.this.private_ip
}

output "security_group_ids" {
  description = "Security groups attached to instance"
  value       = aws_instance.this.vpc_security_group_ids
}

output "iam_instance_profile" {
  description = "IAM instance profile attached to EC2"
  value       = aws_instance.this.iam_instance_profile
}
