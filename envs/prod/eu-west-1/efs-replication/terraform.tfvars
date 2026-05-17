region             = "eu-west-1"
destination_region = "eu-central-1"

destination_kms_key_alias = "alias/prod-dr-efs-replica"
destination_efs_name_tag  = "prod-dr-accesshub-efs-replica"

tags = {
  Environment = "prod"
  Project     = "crave"
  ManagedBy   = "terraform"
  Component   = "efs-replication"
  Direction   = "eu-west-1-to-eu-central-1"
}
