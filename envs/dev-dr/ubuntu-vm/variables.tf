variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "name" {
  description = "VM name"
  type        = string
  default     = "dev-ubuntu-tools"
}

variable "subnet_index" {
  description = "Index into private_app_subnet_ids"
  type        = number
  default     = 0
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root volume size in GiB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "associate_public_ip_address" {
  description = "Associate public IP"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Optional EC2 key pair"
  type        = string
  default     = null
}

variable "ubuntu_ssm_parameter" {
  description = "Ubuntu AMI SSM parameter"
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

variable "install_tools" {
  description = "Install docker, helm, aws-cli, kubectl"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
