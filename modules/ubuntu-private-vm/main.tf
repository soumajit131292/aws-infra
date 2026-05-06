data "aws_ssm_parameter" "ubuntu_ami" {
  name = var.ubuntu_ssm_parameter
}

locals {
  ssm_shell_bootstrap = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    # Ensure ubuntu user is bash-based.
    if id ubuntu >/dev/null 2>&1; then
      chsh -s /bin/bash ubuntu || true
      touch /home/ubuntu/.bash_profile
      grep -q '. ~/.bashrc' /home/ubuntu/.bash_profile || echo '. ~/.bashrc' >> /home/ubuntu/.bash_profile
      chown ubuntu:ubuntu /home/ubuntu/.bash_profile || true
    fi

    # Ensure ssm-user exists with a home directory and bash shell.
    if ! id ssm-user >/dev/null 2>&1; then
      useradd -m -s /bin/bash ssm-user || true
      usermod -aG sudo ssm-user || true
    fi

    mkdir -p /home/ssm-user
    chown ssm-user:ssm-user /home/ssm-user || true
    chsh -s /bin/bash ssm-user || true
    touch /home/ssm-user/.bash_profile
    grep -q '. ~/.bashrc' /home/ssm-user/.bash_profile || echo '. ~/.bashrc' >> /home/ssm-user/.bash_profile
    chown ssm-user:ssm-user /home/ssm-user/.bash_profile || true
  EOT
}

resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  iam_instance_profile        = var.instance_profile_name
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip_address
  vpc_security_group_ids      = var.security_group_ids
  user_data                   = var.configure_ssm_bash_environment ? local.ssm_shell_bootstrap : null

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}
