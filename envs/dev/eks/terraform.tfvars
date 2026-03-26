region            = "us-east-1"
cluster_name      = "dev-accesshub-cluster"
enable_efs_backup = true

tags = {
  Environment = "dev"
  Project     = "crave"
  ManagedBy   = "terraform"
}
