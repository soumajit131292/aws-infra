module "alb_log_athena" {
  source = "../../../../../modules/alb-log-athena"

  name_prefix = var.name_prefix
  region      = var.region
  account_id  = data.aws_caller_identity.current.account_id

  database_name         = var.database_name
  table_name            = var.table_name
  athena_workgroup_name = var.athena_workgroup_name
  projection_start_date = var.projection_start_date
  create_reader_policy  = var.create_reader_policy
  reader_policy_name    = var.reader_policy_name

  alb_logs_bucket_name = data.terraform_remote_state.alb_controller.outputs.alb_access_logs_bucket_name
  alb_logs_prefix      = data.terraform_remote_state.alb_controller.outputs.alb_access_logs_prefix

  athena_results_bucket_name     = data.terraform_remote_state.security_log_pipeline.outputs.bucket_name
  athena_results_prefix          = var.athena_results_prefix
  athena_results_kms_key_arn     = data.terraform_remote_state.security_log_pipeline.outputs.kms_key_arn
  bytes_scanned_cutoff_per_query = var.bytes_scanned_cutoff_per_query

  tags = var.tags
}
