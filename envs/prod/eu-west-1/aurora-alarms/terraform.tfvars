region             = "eu-west-1"
cluster_identifier = "prod-aurora-postgres"

# Reused from the dr-failover alert list ("appropriate personnel").
alert_email_subscribers = [
  "Anil.Meher@craveinfotech.com",
  "soumajit.roy@craveinfotech.com",
]

# Prod-appropriate thresholds (db.r6g.large) — tune to observed baseline.
cpu_utilization_threshold_percent  = 80
read_iops_threshold                = 8000
read_throughput_threshold_bytes    = 104857600   # 100 MB/s
free_local_storage_threshold_bytes = 10737418240 # 10 GB

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
  Component   = "rds-alarms"
}
