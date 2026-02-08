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