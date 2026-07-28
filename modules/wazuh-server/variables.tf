variable "name" {
  description = "Name tag / prefix for the Wazuh server resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the Wazuh server lives in."
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID for the Wazuh server ENI."
  type        = string
}

variable "instance_type" {
  description = "Instance type. Memory-optimized recommended for OpenSearch stability."
  type        = string
  default     = "r6i.large"
}

variable "instance_profile_name" {
  description = "IAM instance profile name (reuse the VPC ec2_ssm profile so SSM Session Manager works without SSH keys)."
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size (GB)."
  type        = number
  default     = 50
}

variable "data_volume_size" {
  description = "Dedicated EBS data volume (GB) mounted for the Wazuh indexer (OpenSearch) data path."
  type        = number
  default     = 100
}

variable "data_volume_type" {
  description = "EBS volume type for the indexer data volume."
  type        = string
  default     = "gp3"
}

variable "admin_cidrs" {
  description = "Trusted admin CIDRs allowed to reach the Wazuh dashboard (TCP 443) and SSH (TCP 22)."
  type        = list(string)
  default     = []
}

variable "agent_source_cidrs" {
  description = "CIDRs allowed to reach agent enrollment/reporting ports (TCP 1514/1515, UDP 1514). Typically the VPC CIDR so in-VPC agents + the Zeek sensor can connect."
  type        = list(string)
}

variable "agent_source_security_group_ids" {
  description = "Optional additional source SGs allowed to reach agent ports (e.g. the EKS node SG)."
  type        = list(string)
  default     = []
}

variable "ubuntu_ssm_parameter" {
  description = "SSM public parameter resolving to the Ubuntu 24.04 AMI ID (matches the ubuntu-private-vm module)."
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

variable "wazuh_version" {
  description = "Wazuh minor version series used by the official all-in-one installer (e.g. 4.9)."
  type        = string
  default     = "4.9"
}

variable "key_name" {
  description = "Optional EC2 key pair for SSH. Leave null and use SSM Session Manager."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
