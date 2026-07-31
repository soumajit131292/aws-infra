# Resolve the cluster's current instance identifiers live (no remote-state coupling).
data "aws_rds_cluster" "this" {
  cluster_identifier = var.cluster_identifier
}
