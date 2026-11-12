region                       = "eu-west-1"
cluster_name                 = "qa-accesshub-cluster"
enable_metrics_server_addon  = true
metrics_server_addon_version = ""

# QA: smaller core nodes than prod (m6i.xlarge), one per AZ.
core_node_instance_types = ["m6i.large"]

# QA: GitHub runners stay on the prod/dev clusters.
enable_spot_runner_node_group = false

cluster_log_retention_in_days = 30
enable_efs_backup             = false
create_efs_logs_file_system   = true

tags = {
  Environment = "qa"
  Project     = "crave"
  ManagedBy   = "terraform"
}
