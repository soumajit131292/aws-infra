region                       = "eu-west-1"
cluster_name                 = "prod-accesshub-cluster"
enable_metrics_server_addon  = true
metrics_server_addon_version = ""

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
}
