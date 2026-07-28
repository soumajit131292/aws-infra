#############################################
# Wazuh All-In-One server — prod (eu-west-1)
#
# Private-only EC2 (SSM access), memory-optimized for OpenSearch,
# with a dedicated indexer data volume. Agents (EKS DaemonSet + the
# Zeek sensor) enrol over 1514/1515 from within the VPC.
#############################################
module "wazuh" {
  source = "../../../../../modules/wazuh-server"

  name          = "prod-wazuh"
  vpc_id        = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_id     = data.terraform_remote_state.vpc.outputs.private_app_subnet_ids[0]
  instance_type = var.instance_type

  instance_profile_name = data.terraform_remote_state.vpc.outputs.ec2_ssm_instance_profile_name

  root_volume_size = var.root_volume_size
  data_volume_size = var.data_volume_size

  admin_cidrs        = var.admin_cidrs
  agent_source_cidrs = [var.vpc_cidr]
  agent_source_security_group_ids = [
    data.terraform_remote_state.vpc.outputs.private_app_sg_id
  ]

  wazuh_version = var.wazuh_version

  tags = var.tags
}
