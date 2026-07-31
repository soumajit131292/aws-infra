region        = "eu-west-1"
vpc_cidr      = "10.20.0.0/16"
instance_type = "m5.large"

# Mirror-session automation is ON, so leave this empty — the Lambda manages
# sessions for the live EKS node ENIs. (Only set this list if you disable
# enable_mirror_automation and want to pin ENIs manually.)
source_network_interface_ids = []

# Lambda + EventBridge auto-syncs mirror sessions as nodes scale/recycle.
enable_mirror_automation = true

# Server CPU-use alerting for the Zeek sensor VM (reused dr-failover alert list).
cpu_threshold_percent = 80
alert_email_subscribers = [
  "Anil.Meher@craveinfotech.com",
  "soumajit.roy@craveinfotech.com",
]

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
  Role        = "siem-zeek-sensor"
}
