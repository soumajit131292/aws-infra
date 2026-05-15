locals {
  # Build "{ ($.kubernetes.namespace_name = "ns1") || ($.kubernetes.namespace_name = "ns2") }"
  ns_filter = length(var.include_namespaces) > 0 ? format(
    "{ %s }",
    join(" || ", [for n in var.include_namespaces : "($.kubernetes.namespace_name = \"${n}\")"])
  ) : ""

  application_log_group = "/aws/containerinsights/${local.cluster_name}/application"
  host_log_group        = "/aws/containerinsights/${local.cluster_name}/host"
  dataplane_log_group   = "/aws/containerinsights/${local.cluster_name}/dataplane"
  eks_audit_log_group   = "/aws/eks/${local.cluster_name}/cluster"

  base_subscriptions = merge(
    var.ship_application ? {
      application = {
        log_group_name = local.application_log_group
        s3_prefix      = "eks/cluster=${local.cluster_name}/source=application/"
        filter_pattern = local.ns_filter
      }
    } : {},
    var.ship_audit ? {
      audit = {
        log_group_name = local.eks_audit_log_group
        s3_prefix      = "audit/cluster=${local.cluster_name}/"
        # Matches Kubernetes audit JSON events; non-JSON control-plane lines are dropped.
        filter_pattern = "{ $.kind = \"Event\" && $.apiVersion = \"audit.k8s.io/v1\" }"
      }
    } : {},
    var.ship_host ? {
      host = {
        log_group_name = local.host_log_group
        s3_prefix      = "eks/cluster=${local.cluster_name}/source=host/"
        filter_pattern = ""
      }
    } : {},
    var.ship_dataplane ? {
      dataplane = {
        log_group_name = local.dataplane_log_group
        s3_prefix      = "eks/cluster=${local.cluster_name}/source=dataplane/"
        filter_pattern = ""
      }
    } : {},
    trimspace(var.ingress_log_group_name) != "" ? {
      ingress = {
        log_group_name = var.ingress_log_group_name
        s3_prefix      = "eks/cluster=${local.cluster_name}/source=ingress/"
        filter_pattern = ""
      }
    } : {}
  )
}

module "security_log_pipeline" {
  source = "../../../../../modules/security-log-pipeline"

  name_prefix   = var.name_prefix
  region        = var.region
  bucket_name   = var.bucket_name
  kms_key_alias = var.kms_key_alias

  object_lock_enabled         = var.object_lock_enabled
  lifecycle_ia_days           = var.lifecycle_ia_days
  lifecycle_glacier_days      = var.lifecycle_glacier_days
  lifecycle_deep_archive_days = var.lifecycle_deep_archive_days
  lifecycle_expiration_days   = var.lifecycle_expiration_days

  firehose_buffer_size_mb          = var.firehose_buffer_size_mb
  firehose_buffer_interval_seconds = var.firehose_buffer_interval_seconds
  firehose_compression_format      = var.firehose_compression_format

  log_subscriptions = local.base_subscriptions

  tags = var.tags
}
