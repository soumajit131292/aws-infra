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
- `tag:Name in [dev-ubuntu-tools, prod-ubuntu-jumphost, prod-dr-ubuntu-jumphost]`
- `instance-state-name = running`
- regions: `us-east-1`, `eu-west-1`, `eu-central-1`

Host is set to `instance_id` and connection uses SSM.
SSM transport needs an S3 bucket for temporary module transfer (configured in inventory).
SSM region is selected per instance from EC2 metadata.
Default inventory user is `ssm-user`; group overrides set `ubuntu` for `env_prod` and `env_prod_dr` to support sudo without password prompts.

## Setup

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

## Test connectivity

```bash
ansible ubuntu_vm -m ping
ansible env_dev -m ping
ansible env_prod -m ping
ansible env_prod_dr -m ping
```

## Run playbook

```bash
ansible-playbook playbook-tools.yml
```

Run only one environment:

```bash
ansible-playbook playbook-tools.yml --limit env_dev
ansible-playbook playbook-tools.yml --limit env_prod
ansible-playbook playbook-tools.yml --limit env_prod_dr
```

## Optional: get instance-id directly with AWS CLI

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=dev-ubuntu-tools" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text
```
