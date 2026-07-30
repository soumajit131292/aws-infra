region        = "eu-west-1"
vpc_cidr      = "10.20.0.0/16"
instance_type = "m5.large"

# Mirror-session automation is ON, so leave this empty — the Lambda manages
# sessions for the live EKS node ENIs. (Only set this list if you disable
# enable_mirror_automation and want to pin ENIs manually.)
source_network_interface_ids = []

# Lambda + EventBridge auto-syncs mirror sessions as nodes scale/recycle.
enable_mirror_automation = true

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
  Role        = "siem-zeek-sensor"
}
