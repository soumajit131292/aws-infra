variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR (allows VXLAN mirror traffic)."
  type        = string
  default     = "10.20.0.0/16"
}

variable "instance_type" {
  description = "Zeek sensor instance type."
  type        = string
  default     = "m5.large"
}

variable "source_network_interface_ids" {
  description = <<-EOT
    EKS worker-node primary ENI IDs to mirror into the sensor. Refresh when
    nodes are replaced. Discover with:

      aws ec2 describe-instances --region eu-west-1 \
        --filters "Name=tag:eks:cluster-name,Values=prod-accesshub-cluster" \
                  "Name=instance-state-name,Values=running" \
        --query "Reservations[].Instances[].NetworkInterfaces[?Attachment.DeviceIndex==\`0\`].NetworkInterfaceId" \
        --output text
  EOT
  type        = list(string)
  default     = []
}

variable "enable_mirror_automation" {
  description = "Deploy the Lambda + EventBridge that auto-syncs mirror sessions with live EKS nodes. When true, leave source_network_interface_ids empty."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
