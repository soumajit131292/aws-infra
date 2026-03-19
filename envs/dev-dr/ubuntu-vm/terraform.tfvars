region                      = "us-west-1"
name                        = "dev-ubuntu-tools"
subnet_index                = 0
instance_type               = "t2.medium"
root_volume_size            = 30
root_volume_type            = "gp3"
associate_public_ip_address = false
install_tools               = true

tags = {
  env   = "dev"
  owner = "terraform-accesshub-platform"
}
