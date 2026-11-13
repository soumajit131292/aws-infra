output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ubuntu_vm.instance_id
}

output "private_ip" {
  description = "Instance private IP"
  value       = module.ubuntu_vm.private_ip
}

output "security_group_ids" {
  description = "Security group IDs"
  value       = module.ubuntu_vm.security_group_ids
}

output "instance_profile" {
  description = "Attached IAM instance profile"
  value       = module.ubuntu_vm.iam_instance_profile
}

output "instance_role_arn" {
  description = "IAM role of the jumphost (granted cluster-admin on the QA EKS cluster)."
  value       = data.terraform_remote_state.vpc.outputs.ec2_ssm_role_arn
}
