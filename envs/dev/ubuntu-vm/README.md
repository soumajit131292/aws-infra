# Ubuntu Tools VM (dev)

This stack provisions one Ubuntu EC2 instance in a private app subnet and attaches the existing VPC SSM instance profile.

Installed via cloud-init:
- Docker
- Helm
- AWS CLI
- kubectl

## Apply

```bash
cd envs/dev/ubuntu-vm
terraform init
terraform plan
terraform apply
```

## Access

Use AWS Systems Manager Session Manager (no public IP required).
