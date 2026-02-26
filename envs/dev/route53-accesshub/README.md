# Route 53 alias for AccessHub ALB

This stack creates public Route 53 alias records (`A` and `AAAA`) that point your domain name to the ALB created by Kubernetes ingress.

## Configure

Edit `terraform.tfvars`:

- `hosted_zone_name`: your public hosted zone, with trailing dot (example: `mydomain.com.`)
- `record_name`: desired DNS name (example: `accesshub-dev.mydomain.com`)
- `alb_name`: ALB name from ingress annotations (`accesshub-dev-alb`)

## Apply

```bash
terraform -chdir=envs/dev/route53-accesshub init
terraform -chdir=envs/dev/route53-accesshub plan
terraform -chdir=envs/dev/route53-accesshub apply
```
