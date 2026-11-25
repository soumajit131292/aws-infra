# Prod ACM certificate rotation

The current certificate for `prod-aws.accesshub-identity.com` is referenced by
the prod AccessHub ALB configuration and Grafana. This stack supports issuing a
second certificate without replacing or detaching the current certificate.

## Issue the replacement

From this directory:

```bash
terraform init
terraform plan
```

Review that the plan creates only `aws_acm_certificate.replacement[0]` and
`aws_acm_certificate_validation.replacement[0]` for the replacement. It must
not replace or destroy `module.acm_public_cert` or the existing DNS validation
record. Then apply:

```bash
terraform apply
terraform output -raw replacement_certificate_arn
```

The validation resource waits for ACM to issue the certificate. The existing
DNS validation CNAME is shared for the same account and domain; ACM allows it
to validate additional certificates.

After issuance, keep `wait_for_validation = false` while the expired original
certificate remains in this stack. This removes Terraform's old validation
waiter, which otherwise keeps polling the expired certificate and causes an
apply error. The replacement certificate itself remains managed by
`aws_acm_certificate.replacement[0]` and is exposed by the replacement output.

## Deploy the new ARN

Replace the old ARN with the output ARN in these files:

1. `helm-charts/helm/accesshub/values-prod.yaml` — AccessHub prod ALB.
2. `helm-charts/helm/accesshub/values-health-prod.yaml` — health-check chart
   configuration (used by the prod health-check application where deployed).
3. `envs/prod/eu-west-1/eks-add-on/grafana/terraform.tfvars` — Grafana ingress.

Commit and deploy the Helm value change through the prod Argo CD application;
apply the Grafana Terraform stack after reviewing its plan. Keep the old
certificate in ACM until every ALB listener that used it reports the new ARN.

Check the certificate attachment:

```bash
aws elbv2 describe-listeners --region eu-west-1 \
  --load-balancer-arn arn:aws:elasticloadbalancing:eu-west-1:495711089104:loadbalancer/app/accesshub-prod-alb/fac3fec59726c7cd \
  --query 'Listeners[].{Port:Port,Protocol:Protocol,Certificates:Certificates[].CertificateArn}' \
  --output json
```

Once the old ARN is no longer attached, remove it from ACM Terraform state/config
in a separate reviewed change. Do not turn off replacement issuance before
deciding whether the new certificate should remain managed by this stack.
