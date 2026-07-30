#############################################
# Zeek network sensor — prod (eu-west-1)
#
# Dedicated Zeek sensor + VPC Traffic Mirroring of the EKS worker-node
# ENIs. On-sensor Wazuh agent ships Zeek http/dns/conn logs to the
# Wazuh manager. Populate source_network_interface_ids with the current
# node ENIs (see README for the discovery command).
#############################################
module "zeek_sensor" {
  source = "../../../../../modules/zeek-sensor"

  name          = "prod-zeek-sensor"
  vpc_id        = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_id     = data.terraform_remote_state.vpc.outputs.private_app_subnet_ids[0]
  vpc_cidr      = var.vpc_cidr
  instance_type = var.instance_type

  instance_profile_name = data.terraform_remote_state.vpc.outputs.ec2_ssm_instance_profile_name

  wazuh_manager_ip = data.terraform_remote_state.wazuh.outputs.wazuh_private_ip
  wazuh_agent_name = "prod-zeek-sensor"

  source_network_interface_ids = var.source_network_interface_ids

  tags = var.tags
}

#############################################
# Auto-manage mirror sessions as nodes scale/recycle.
# When enabled, leave source_network_interface_ids empty and let the
# Lambda create/delete sessions for the live EKS worker-node ENIs.
#############################################
module "mirror_automation" {
  count  = var.enable_mirror_automation ? 1 : 0
  source = "../../../../../modules/zeek-mirror-automation"

  name             = "prod-zeek-mirror-automation"
  cluster_name     = data.terraform_remote_state.eks.outputs.cluster_name
  mirror_target_id = module.zeek_sensor.traffic_mirror_target_id
  mirror_filter_id = module.zeek_sensor.traffic_mirror_filter_id

  tags = var.tags
}
