locals {
  chart_path = var.chart_path != "" ? var.chart_path : "${path.module}/argo-cd"

  rendered_values = concat(
    [file("${path.module}/values-ecr-images.yaml")],
    [for file_path in var.values_files : file(file_path)],
    var.values,
  )
}

resource "kubernetes_namespace" "argocd" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "argocd_redis_auth" {
  metadata {
    name      = var.redis_auth_secret_name
    namespace = var.namespace
  }

  data = {
    auth = random_password.redis_auth.result
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.argocd]
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

  depends_on = [kubernetes_secret.argocd_redis_auth]
}
