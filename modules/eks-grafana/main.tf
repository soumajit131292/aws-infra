locals {
  grafana_chart_path_effective = trimspace(var.grafana_chart_path) != "" ? trimspace(var.grafana_chart_path) : "${path.module}/../grafana/grafana"
  oidc_issuer_hostpath         = replace(var.oidc_issuer_url, "https://", "")
  irsa_role_name_effective     = trimspace(var.irsa_role_name) != "" ? trimspace(var.irsa_role_name) : "${var.cluster_name}-grafana-amp-irsa"
  amp_workspace_id             = trimspace(var.amp_workspace_arn) != "" ? element(split("/", var.amp_workspace_arn), 1) : ""
  amp_datasource_url           = local.amp_workspace_id != "" ? "https://aps-workspaces.${var.amp_region}.amazonaws.com/workspaces/${local.amp_workspace_id}" : ""
  grafana_plugins_effective    = distinct(concat(var.grafana_plugins, var.enable_amp_plugin_install ? [var.amp_plugin_id] : []))
}

resource "kubernetes_namespace" "grafana" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

data "aws_iam_policy_document" "grafana_assume_role" {
  count = var.enable_irsa ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
  }
}

resource "aws_iam_role" "grafana_irsa" {
  count = var.enable_irsa ? 1 : 0

  name               = local.irsa_role_name_effective
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role[0].json
}

data "aws_iam_policy_document" "grafana_amp" {
  count = var.enable_irsa && trimspace(var.amp_workspace_arn) != "" ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "aps:QueryMetrics",
      "aps:GetSeries",
      "aps:GetLabels",
      "aps:GetMetricMetadata"
    ]
    resources = [var.amp_workspace_arn]
  }
}

resource "aws_iam_role_policy" "grafana_amp" {
  count = var.enable_irsa && trimspace(var.amp_workspace_arn) != "" ? 1 : 0

  name   = "${local.irsa_role_name_effective}-amp"
  role   = aws_iam_role.grafana_irsa[0].id
  policy = data.aws_iam_policy_document.grafana_amp[0].json
}

resource "helm_release" "grafana" {
  name      = var.grafana_release_name
  namespace = var.namespace
  chart     = local.grafana_chart_path_effective

  create_namespace = false
  wait             = true
  timeout          = 600

  values = concat([
    yamlencode(merge(
      {
        image = {
          registry   = var.grafana_image_registry
          repository = var.grafana_image_repository
          tag        = var.grafana_image_tag
        }
        plugins = local.grafana_plugins_effective
        testFramework = {
          enabled = false
        }
        initChownData = {
          enabled = true
          image = {
            registry   = var.init_chown_image_registry
            repository = var.init_chown_image_repository
            tag        = var.init_chown_image_tag
          }
        }
        serviceAccount = {
          create = true
          name   = var.service_account_name
          annotations = var.enable_irsa ? {
            "eks.amazonaws.com/role-arn" = aws_iam_role.grafana_irsa[0].arn
          } : {}
        }
      },
      var.enable_amp_datasource && local.amp_datasource_url != "" ? {
        datasources = {
          "datasources.yaml" = {
            apiVersion = 1
            datasources = [
              {
                name      = var.amp_datasource_name
                type      = var.amp_datasource_type
                access    = "proxy"
                url       = local.amp_datasource_url
                isDefault = true
                jsonData = {
                  sigV4Auth   = true
                  sigV4Region = var.amp_region
                }
              }
            ]
          }
        }
      } : {}
    ))
  ], var.grafana_extra_values)

  depends_on = [
    kubernetes_namespace.grafana,
    aws_iam_role_policy.grafana_amp
  ]
}
