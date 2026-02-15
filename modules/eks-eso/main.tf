locals {
  chart_path = var.chart_path != "" ? var.chart_path : "${path.module}/external-secrets"

  rendered_values = concat(
    [for file_path in var.values_files : file(file_path)],
    var.values,
  )
}

resource "kubernetes_namespace" "external_secrets" {
  count = var.create_namespace && var.manage_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "helm_release" "external_secrets" {
  name             = var.release_name
  namespace        = var.namespace
  chart            = local.chart_path
  create_namespace = var.create_namespace

  atomic          = var.atomic
  cleanup_on_fail = false
  wait            = true
  timeout         = var.timeout

  values = local.rendered_values

  dynamic "set" {
    for_each = var.set

    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [kubernetes_namespace.external_secrets]
}
