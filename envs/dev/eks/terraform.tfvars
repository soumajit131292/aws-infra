region                       = "us-east-1"
cluster_name                 = "dev-accesshub-cluster"
enable_metrics_server_addon  = true
metrics_server_addon_version = ""

tags = {
  Environment = "dev"
  Project     = "crave"
  ManagedBy   = "terraform"
}
