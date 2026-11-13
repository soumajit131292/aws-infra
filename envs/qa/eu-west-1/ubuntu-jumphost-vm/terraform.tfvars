region                      = "eu-west-1"
name                        = "qa-ubuntu-jumphost"
subnet_index                = 0
instance_type               = "t3.small"
root_volume_size            = 30
root_volume_type            = "gp3"
associate_public_ip_address = false
install_tools               = true

# env = qa puts the instance in the Ansible env_qa group (keyed_groups).
tags = {
  env   = "qa"
  owner = "terraform-accesshub-platform"
}
