region = "us-east-1"

namespace                   = "velero"
helm_release_name           = "velero"
use_local_chart             = true
velero_chart_version        = "7.2.1"
velero_service_account_name = "velero"
velero_image_repository     = "velero/velero"
velero_image_tag            = "v1.14.1"
velero_plugin_image         = "velero/velero-plugin-for-aws:v1.10.0"

create_backup_bucket = true
backup_bucket_name   = ""

tags = {
  component = "velero"
  env       = "dev"
}
