# Resolve the cluster's current instance identifiers live.
data "aws_rds_cluster" "this" {
  cluster_identifier = var.cluster_identifier
}
