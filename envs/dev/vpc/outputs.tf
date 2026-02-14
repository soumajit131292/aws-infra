output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs"
  value       = module.network.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs"
  value       = module.network.private_db_subnet_ids
}

output "private_app_sg_id" {
  description = "Private application security group ID"
  value       = module.network.private_app_sg_id
}

output "private_db_sg_id" {
  description = "Private DB security group ID"
  value       = module.network.private_db_sg_id
}
