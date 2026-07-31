# Server CPU-use monitoring for the Wazuh VM (standalone pet server) -> SNS.
module "cpu_alarm" {
  source = "../../../../../modules/ec2-cpu-alarm"

  name_prefix             = "prod-wazuh"
  instances               = { "prod-wazuh" = module.wazuh.instance_id }
  cpu_threshold_percent   = var.cpu_threshold_percent
  alert_email_subscribers = var.alert_email_subscribers

  tags = var.tags
}
