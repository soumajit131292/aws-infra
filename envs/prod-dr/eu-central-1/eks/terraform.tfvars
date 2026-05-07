region                       = "eu-central-1"
cluster_name                 = "prod-dr-accesshub-cluster"
enable_metrics_server_addon  = true
metrics_server_addon_version = ""

tags = {
  Environment = "prod-dr"
  Project     = "crave"
  ManagedBy   = "terraform"
}
