locals {
  chart_path = var.chart_path != "" ? var.chart_path : "${path.module}/argo-cd"

  rendered_values = concat(
    [file("${path.module}/values-ecr-images.yaml")],
    [for file_path in var.values_files : file(file_path)],
    var.values,
  )
}

resource "helm_release" "argocd" {
  name             = var.release_name
  namespace        = var.namespace
  chart            = local.chart_path
  create_namespace = var.create_namespace

  atomic          = true
  cleanup_on_fail = true
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
}
