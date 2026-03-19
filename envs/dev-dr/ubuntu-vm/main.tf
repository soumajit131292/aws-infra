module "ubuntu_vm" {
  source = "../../../modules/ubuntu-private-vm"

  name                        = var.name
  subnet_id                   = data.terraform_remote_state.vpc.outputs.private_app_subnet_ids[var.subnet_index]
  instance_profile_name       = data.terraform_remote_state.vpc.outputs.ec2_ssm_instance_profile_name
  instance_type               = var.instance_type
  root_volume_size            = var.root_volume_size
  root_volume_type            = var.root_volume_type
  associate_public_ip_address = var.associate_public_ip_address
  security_group_ids          = [data.terraform_remote_state.vpc.outputs.private_app_sg_id]
  key_name                    = var.key_name
  ubuntu_ssm_parameter        = var.ubuntu_ssm_parameter
  install_tools               = var.install_tools
  tags                        = var.tags
}
