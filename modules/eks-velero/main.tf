resource "helm_release" "velero" {
  name       = var.release_name
  namespace  = var.namespace
  repository = var.use_local_chart ? null : var.chart_repository
  chart      = var.use_local_chart ? "${path.module}/${var.local_chart_path}" : var.chart_name
  version    = var.use_local_chart ? null : var.chart_version

  values = concat([
    yamlencode({
      image = {
        repository = var.velero_image_repository
        tag        = var.velero_image_tag
      }

      serviceAccount = {
        server = {
          create = false
          name   = var.service_account_name
        }
      }

      initContainers = [
        {
          name  = "velero-plugin-for-aws"
          image = var.aws_plugin_image
          volumeMounts = [
            {
              mountPath = "/target"
              name      = "plugins"
            }
          ]
        }
      ]

      credentials = {
        useSecret = false
      }

      configuration = {
        backupStorageLocation = [
          {
            name     = "default"
            provider = "aws"
            bucket   = var.backup_bucket_name
            config = {
              region = var.aws_region
            }
          }
        ]

        volumeSnapshotLocation = [
          {
            name     = "default"
            provider = "aws"
            config = {
              region = var.aws_region
            }
          }
        ]
      }
    })
  ], var.extra_values)
}
