region             = "us-east-1"
cluster_identifier = "dev-aurora-postgres"

# Reused from the dr-failover alert list ("appropriate personnel").
alert_email_subscribers = [
  "Anil.Meher@craveinfotech.com",
  "soumajit.roy@craveinfotech.com",
]

tags = {
  Environment = "dev"
  Project     = "crave"
  ManagedBy   = "terraform"
  Component   = "rds-alarms"
}
