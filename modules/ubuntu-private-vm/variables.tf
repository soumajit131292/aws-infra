variable "name" {
  description = "Name prefix for the VM"
  type        = string
}

variable "subnet_id" {
  description = "Private app subnet ID"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name to attach to EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP"
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "Security groups to attach to the instance"
  type        = list(string)
}

variable "key_name" {
  description = "Optional EC2 key pair name"
  type        = string
  default     = null
}

variable "ubuntu_ssm_parameter" {
  description = "SSM parameter path for Ubuntu AMI"
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

variable "install_tools" {
  description = "Install docker, helm, aws-cli, kubectl using cloud-init"
  type        = bool
  default     = true
}

variable "configure_ssm_bash_environment" {
  description = "Configure ssm-user/ubuntu with bash login shell and home profile during instance launch"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
