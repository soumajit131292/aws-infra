resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier = var.global_cluster_identifier
  force_destroy             = var.force_destroy

  # Adopts the existing prod Aurora cluster as the primary of the global
  # cluster. This is an online operation -- no recreation of the source
  # cluster, no data loss. Engine, engine_version, database_name, and
  # storage_encrypted are inherited from the source cluster.
  source_db_cluster_identifier = data.terraform_remote_state.prod_aurora.outputs.cluster_arn

  lifecycle {
    # source_db_cluster_identifier is only meaningful at creation time. After
    # adoption, AWS no longer tracks it, but Terraform would compare config to
    # state and could spuriously plan changes. Ignoring it locks in the
    # one-shot adoption semantics.
    ignore_changes = [source_db_cluster_identifier]
  }
}
