region = "eu-west-1"

namespace                   = "velero"
helm_release_name           = "velero"
use_local_chart             = true
velero_chart_version        = "7.2.1"
velero_service_account_name = "velero"
velero_image_repository     = "495711089104.dkr.ecr.eu-west-1.amazonaws.com/thirdparty/velero"
velero_image_tag            = "v1.14.1-amd64-platform"
velero_plugin_image         = "495711089104.dkr.ecr.eu-west-1.amazonaws.com/thirdparty/velero-plugin-for-aws:v1.10.0-amd64-platform"
kubectl_image_repository    = "495711089104.dkr.ecr.eu-west-1.amazonaws.com/thirdparty/kubectl"
kubectl_image_tag           = "latest-amd64-platform"

create_backup_bucket                    = true
backup_bucket_name                      = ""
create_velero_kms_key                   = true
velero_kms_key_alias                    = "prod-velero-backups"
backup_bucket_retention_days            = 7
backup_bucket_noncurrent_retention_days = 7
enable_default_backup_schedule          = true
backup_schedule_cron                    = "0 2 * * *"
backup_schedule_ttl_hours               = 168

tags = {
  component = "velero"
  env       = "prod"
}
