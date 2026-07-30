variable "name" {
  description = "Name tag / prefix for the Zeek sensor resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the sensor lives in."
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID for the sensor ENI (should be in the VPC being mirrored)."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR — used to allow the VXLAN (UDP 4789) mirrored traffic from source ENIs."
  type        = string
}

variable "instance_type" {
  description = "Sensor instance type. Zeek is CPU-bound on packet parsing; size to mirrored throughput."
  type        = string
  default     = "m5.large"
}

variable "instance_profile_name" {
  description = "IAM instance profile (reuse the VPC ec2_ssm profile for SSM access)."
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size (GB). Zeek logs rotate hourly under /opt/zeek/logs."
  type        = number
  default     = 100
}

variable "wazuh_manager_ip" {
  description = "Private IP of the Wazuh manager the on-sensor Wazuh agent reports to."
  type        = string
}

variable "wazuh_agent_name" {
  description = "Stable Wazuh agent name to register for the Zeek sensor."
  type        = string
  default     = null
}

variable "capture_interface" {
  description = "Interface Zeek listens on. For a mirror target this is the primary ENI (ens5 on Nitro)."
  type        = string
  default     = "ens5"
}

variable "source_network_interface_ids" {
  description = <<-EOT
    ENI IDs to mirror INTO this sensor (typically the EKS worker node primary ENIs).
    One traffic-mirror session is created per ENI. NOTE: managed node group
    instances are ephemeral — when nodes are replaced these ENI IDs change, so
    this list must be refreshed (or automated via a tag-driven Lambda). See the
    stack README for a discovery command.
  EOT
  type        = list(string)
  default     = []
}

variable "traffic_mirror_vni" {
  description = "VXLAN network identifier for the mirror sessions."
  type        = number
  default     = 4789
}

variable "ubuntu_ssm_parameter" {
  description = "SSM public parameter for the Ubuntu 24.04 AMI ID."
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

variable "key_name" {
  description = "Optional EC2 key pair. Leave null and use SSM Session Manager."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
