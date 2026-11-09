#############################################
# Wazuh agent DaemonSet — prod (eu-west-1)
#
# One agent per EKS node, reporting to the Wazuh all-in-one server
# (security/wazuh). Image is mirrored to ECR by scripts/mirror-images-to-ecr.sh.
#############################################
module "wazuh_agent" {
  source = "../../../../../modules/eks-wazuh-agent"

  namespace    = var.namespace
  release_name = var.release_name

  manager_address = data.terraform_remote_state.wazuh.outputs.wazuh_private_ip
  agent_group     = var.agent_group
  cluster_name    = data.terraform_remote_state.eks.outputs.cluster_name

  image_registry   = var.image_registry
  image_repository = var.image_repository
  image_tag        = var.image_tag

  container_log_namespaces = var.container_log_namespaces
  enable_journald          = var.enable_journald
}
