region   = "eu-west-1"
vpc_cidr = "10.20.0.0/16"

instance_type    = "r6i.large" # 2 vCPU / 16 GB — prod-appropriate for OpenSearch
root_volume_size = 50
data_volume_size = 100
wazuh_version    = "4.9"

# REQUIRED: lock the dashboard + SSH to your admin/VPN ranges before apply.
# Leaving this empty means NO 443/22 ingress is created (SSM still works).
admin_cidrs = []

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
  Role        = "siem-wazuh"
}
