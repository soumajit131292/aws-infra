# Dev Infrastructure Deployment Runbook

## 1. Prerequisites
- AWS CLI configured for target account and region.
- Terraform `>= 1.5`.
- Access to Terraform backend bucket: `crave-infra-terraform-state-bucket`.
- For private EKS endpoint operations: run from host that can reach private EKS API (private jump host/SSM VM).

## 2. One-time Foundation (Per Account)

### 2.1 Bootstrap
Path: `envs/dev/bootstrap`

```bash
cd envs/dev/bootstrap
terraform init
terraform plan
terraform apply
```

### 2.2 GitHub OIDC Role
Path: `envs/dev/github-oidc-role`

```bash
cd envs/dev/github-oidc-role
terraform init
terraform plan
terraform apply
```

## 3. Network Layer

### 3.1 VPC
Path: `envs/dev/vpc`

```bash
cd envs/dev/vpc
terraform init
terraform plan
terraform apply
```

## 4. Platform Core

### 4.1 EKS
Path: `envs/dev/eks`

```bash
cd envs/dev/eks
terraform init
terraform plan
terraform apply
```

### 4.2 Aurora PostgreSQL
Path: `envs/dev/aurora-postgres`

```bash
cd envs/dev/aurora-postgres
terraform init
terraform plan
terraform apply
```

## 5. EKS Add-ons (Apply In Order)
Run from host with network access to private EKS endpoint.

### 5.1 ALB Controller
Path: `envs/dev/eks-add-on/alb-controller`

```bash
cd envs/dev/eks-add-on/alb-controller
terraform init
terraform plan
terraform apply
```

### 5.2 External Secrets
Path: `envs/dev/eks-add-on/external-secrets`

```bash
cd envs/dev/eks-add-on/external-secrets
terraform init
terraform plan
terraform apply
```

### 5.3 Argo CD (if used)
Path: `envs/dev/eks-add-on/argocd`

```bash
cd envs/dev/eks-add-on/argocd
terraform init
terraform plan
terraform apply
```

### 5.4 Node Monitoring
Path: `envs/dev/eks-add-on/node-monitoring`

```bash
cd envs/dev/eks-add-on/node-monitoring
terraform init
terraform plan
terraform apply
```

### 5.5 Managed Prometheus (AMP Scraper)
Path: `envs/dev/eks-add-on/managed-prometheus`

```bash
cd envs/dev/eks-add-on/managed-prometheus
terraform init
terraform plan
terraform apply
```

### 5.6 Grafana
Path: `envs/dev/eks-add-on/grafana`

```bash
cd envs/dev/eks-add-on/grafana
terraform init
terraform plan
terraform apply
```

### 5.7 Velero (if enabled)
Path: `envs/dev/eks-add-on/velero`

```bash
cd envs/dev/eks-add-on/velero
terraform init
terraform plan
terraform apply
```

## 6. Optional Stacks
- GitHub runners: `envs/dev/github-runner`
- Route53 records: `envs/dev/route53-accesshub`
- Any additional env stacks as required.

## 7. Image Mirroring (Private ECR-only Environments)
Run mirror scripts before applying add-ons/charts that reference private ECR images.

Examples:
- `envs/dev/eks-add-on/argocd/scripts/mirror-images-to-ecr.sh`
- `envs/dev/eks-add-on/node-monitoring/scripts/mirror-images-to-ecr.sh`
- `envs/dev/eks-add-on/velero/scripts/mirror-images-to-ecr.sh`
- `envs/dev/eks-add-on/grafana/scripts/mirror-images-to-ecr.sh`

## 8. Post-deployment Validation

### 8.1 EKS health
```bash
kubectl get nodes
kubectl get pods -A
```

### 8.2 Ingress/ALB
```bash
kubectl get ingress -A
```

### 8.3 Monitoring
- AMP workspace/scraper active.
- Grafana datasource and dashboards visible.

### 8.4 Database
- Application connectivity to Aurora writer/proxy endpoint validated.

## 9. Destroy Order (Reverse Dependency Order)
1. EKS add-ons
2. App stacks depending on EKS/VPC (runners, route53, etc.)
3. Aurora
4. EKS
5. VPC
6. Foundation modules (`github-oidc-role`, `bootstrap`) only for full teardown

## 10. Notes
- Avoid routine use of `terraform apply -target`; use only for recovery scenarios.
- Prefer `terraform plan` before every apply.
- For private endpoint clusters, run EKS/add-on applies from private network path.
