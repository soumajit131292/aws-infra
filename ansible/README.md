# Ansible: Install DevOps Tools via AWS SSM

This playbook installs the following on Ubuntu:
- aws-cli
- helm
- kubectl
- docker
- terraform

## Files
- `ansible.cfg`
- `inventory.aws_ec2.yml` (dynamic inventory by EC2 tag)
- `inventory.ini` (static fallback)
- `requirements.yml`
- `playbook-tools.yml`
- `roles/devops_tools/*`

## Prerequisites on laptop
- AWS CLI configured (same access you use for `aws ssm start-session`)
- `session-manager-plugin` installed
- Ansible installed

## Dynamic discovery by VM name

`inventory.aws_ec2.yml` discovers EC2 instances with:
- `tag:Name = dev-ubuntu-tools`
- `instance-state-name = running`

Host is set to `instance_id` and connection uses SSM.
SSM transport needs an S3 bucket for temporary module transfer (configured in inventory).

## Setup

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

## Test connectivity

```bash
ansible ubuntu_vm -m ping
```

## Run playbook

```bash
ansible-playbook playbook-tools.yml
```

## Optional: get instance-id directly with AWS CLI

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=dev-ubuntu-tools" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text
```
