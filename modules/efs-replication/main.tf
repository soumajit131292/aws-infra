resource "aws_efs_replication_configuration" "this" {
  source_file_system_id = var.source_file_system_id

  destination {
    region                 = var.destination_region
    kms_key_id             = var.destination_kms_key_arn
    availability_zone_name = var.destination_availability_zone_name
  }
}
