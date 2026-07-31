region   = "eu-west-1"
vpc_cidr = "10.20.0.0/16"

instance_type    = "r6i.large" # 2 vCPU / 16 GB — prod-appropriate for OpenSearch
root_volume_size = 50
data_volume_size = 100
wazuh_version    = "4.9"
retention_days   = 21 # Wazuh index retention (days) enforced via ISM policy

# Server CPU-use alerting for the Wazuh VM (reused dr-failover alert list).
cpu_threshold_percent = 80
alert_email_subscribers = [
  "Anil.Meher@craveinfotech.com",
  "soumajit.roy@craveinfotech.com",
]

# Required for browsing raw Zeek conn/dns/http records in wazuh-archives-*.
# This increases index volume because Wazuh stores all received events.
enable_logall_json      = true
enable_archive_indexing = true

# REQUIRED: lock the dashboard + SSH to your admin/VPN ranges before apply.
# Leaving this empty means NO 443/22 ingress is created (SSM still works).
admin_cidrs = []

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
  Role        = "siem-wazuh"
}
