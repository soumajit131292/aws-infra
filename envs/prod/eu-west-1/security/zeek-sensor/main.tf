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

  source_network_interface_ids = var.source_network_interface_ids

  tags = var.tags
}
