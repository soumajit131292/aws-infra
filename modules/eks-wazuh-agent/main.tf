locals {
  chart_path = var.chart_path != "" ? var.chart_path : "${path.module}/wazuh-agent"

  base_values = yamlencode({
    image = {
      registry   = var.image_registry
      repository = var.image_repository
      tag        = var.image_tag
    }
    manager = {
      address = var.manager_address
    }
    agent = {
      group = var.agent_group
      labels = {
        cluster = var.cluster_name
      }
    }
    collect = {
      containerLogNamespaces = var.container_log_namespaces
      journald = {
        enabled = var.enable_journald
      }
    }
  })
}

# The agent needs privileged + hostPID/hostNetwork, so the namespace must allow
# the "privileged" Pod Security level.
resource "kubernetes_namespace" "wazuh" {
  metadata {
    name = var.namespace

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "wazuh_agent" {
  name      = var.release_name
  namespace = kubernetes_namespace.wazuh.metadata[0].name
  chart     = local.chart_path

  atomic          = var.atomic
  cleanup_on_fail = false
  wait            = true
  timeout         = var.timeout

  values = concat([local.base_values], var.values)
}
