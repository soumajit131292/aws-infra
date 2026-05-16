# AccessHub Helm Chart

Deploys all AccessHub backend services as separate Deployments/Services.

## Required values

Set these before deploy:

- `global.imageRegistry` (example: `495711089104.dkr.ecr.us-east-1.amazonaws.com`)
- `global.imageTag` (example: `sha-<gitsha>` or `latest`)
- `global.database.host`
- `global.database.name`
- `global.database.user` and `global.database.password` (or use existing Secret)

## Install

```bash
helm upgrade --install accesshub deploy/helm/accesshub \
  -n accesshub --create-namespace \
  --set global.imageRegistry=495711089104.dkr.ecr.us-east-1.amazonaws.com \
  --set global.imageTag=latest \
  --set global.database.mode=POSTGRES \
  --set global.database.host=<aurora-endpoint> \
  --set global.database.port=5432 \
  --set global.database.name=<db_name> \
  --set global.database.user=<db_user> \
  --set global.database.password=<db_password>
```

## Argo CD

Use this chart path in your Argo CD Application:

- `repoURL`: your Git repo
- `path`: `deploy/helm/accesshub`
- `targetRevision`: branch/tag

Then set Helm values (or valueFiles) in Argo CD.

## ALB Ingress

This chart supports a single AWS ALB Ingress with path-based routing.

Enable in values:

```yaml
ingress:
  enabled: true
  className: alb
  host: accesshub.example.com
  annotations:
    alb.ingress.kubernetes.io/load-balancer-name: accesshub-dev-alb
    alb.ingress.kubernetes.io/group.name: accesshub-dev
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
```

Note: AWS ALB does not support fixed/reserved static public IPs. For static ingress IPs, use AWS Global Accelerator in front of ALB, or switch to NLB with Elastic IPs.

Current default paths map to services from your Apache config that exist in this chart.
Routes like `/kpgateway`, `/registerApplication`, `/jobcontroller`, and `/restsignature` are not included because those backing services are not currently part of this Helm chart.

## Option 1: existing Kubernetes Secret for DB creds

Create secret:

```bash
kubectl -n accesshub create secret generic accesshub-db \
  --from-literal=username='<db-user>' \
  --from-literal=password='<db-password>'
```

Set values:

```yaml
global:
  database:
    existingSecret: accesshub-db
    existingSecretUserKey: username
    existingSecretPasswordKey: password
```

## Database host/name via ConfigMap

You can provide `DB_HOST` and `DB_NAME` via ConfigMap.

Use an existing ConfigMap:

```yaml
global:
  database:
    existingConfigMap: accesshub-db-config
    existingConfigMapHostKey: host
    existingConfigMapNameKey: name
```

Or let this chart create it from values:

```yaml
global:
  database:
    configMap:
      create: true
      name: accesshub-db-config
    host: <aurora-endpoint>
    name: <db-name>
```

Example manifest:

- `deployment/helm/accesshub/examples/db-configmap.yaml`

## Option 2: External Secrets Operator + AWS Secrets Manager (recommended)

Enable in values:

```yaml
externalSecret:
  enabled: true
  secretStoreRef:
    create: true
    kind: ClusterSecretStore
    name: aws-secretsmanager
    aws:
      region: us-east-1
      auth:
        serviceAccount:
          name: external-secrets
          namespace: external-secrets
  target:
    name: accesshub-db
  data:
    username:
      remoteRef:
        key: /accesshub/prod/db
        property: username
    password:
      remoteRef:
        key: /accesshub/prod/db
        property: password
```

When `externalSecret.enabled=true`, chart deployments automatically read DB user/password from `externalSecret.target.name` unless `global.database.existingSecret` is explicitly set.

When `externalSecret.secretStoreRef.create=true` and `externalSecret.secretStoreRef.kind=ClusterSecretStore`, this chart also creates the `ClusterSecretStore` resource named in `externalSecret.secretStoreRef.name`.

## Runtime property init

The Docker entrypoint scripts now run `/usr/local/bin/run-config-init.sh` before service startup.
This updates legacy property files (for example `allServices.properties`, `JWTConfig.properties`,
`scimConfig.properties`, and `ApplicationRegistration/config.properties`) from Helm env values:

```yaml
global:
  runtime:
    baseUrl: https://dev1.accesshub.ai
    tenantId: TEST
    nativeSuperadminId: admin
    nativeSuperadminPassword: admin
    grcApiAccessUser: grcuser
    grcApiAccessPassword: <secret>
```

You can also read these runtime values from a dedicated Kubernetes Secret:

```yaml
global:
  runtime:
    existingSecret: accesshub-runtime
```

Key names are configurable in `values.yaml`:

- `global.runtime.existingSecretBaseUrlKey`
- `global.runtime.existingSecretTenantIdKey`
- `global.runtime.existingSecretNativeSuperadminIdKey`
- `global.runtime.existingSecretNativeSuperadminPasswordKey`
- `global.runtime.existingSecretGrcApiAccessUserKey`
- `global.runtime.existingSecretGrcApiAccessPasswordKey`

Example secret manifest:

- `deployment/helm/accesshub/examples/runtime-secret.yaml`

## Tenant bootstrap Job

Use the one-time tenant bootstrap Job to run `tenantsetup.sh` after deployment:

```yaml
tenantBootstrap:
  enabled: true
  backoffLimit: 2
  ttlSecondsAfterFinished: null
  image:
    repository: accesshub/bootstrap
    digest: sha256:<bootstrap-image-digest>
```

For true one-time-safe behavior with Argo CD, keep `ttlSecondsAfterFinished: null` (or unset).
That keeps the completed Job object in the cluster, so later syncs do not recreate and rerun it.

By default this Job uses the `gatewaysvc` image. You can override it with
`tenantBootstrap.image.repository` and `tenantBootstrap.image.digest`.

The Job runs:

- `run-config-init.sh --tenant-only`
- `/app/Accesshub_Files/Install_Scripts/tenantsetup.sh`

## Health Aggregator (optional)

Use this lightweight service to aggregate backend health endpoints into one `/healthz` result for Route53/ALB checks.

Enable in values:

```yaml
healthAggregator:
  enabled: true
  image:
    repository: accesshub/health-aggregator
    digest: sha256:<digest>
```

By design, image build is decoupled from app-service matrix builds and handled by
`.github/workflows/build-health-aggregator.yml`, which updates
`healthAggregator.image.digest` only when `health-aggregator/**` changes.

To expose it through ALB ingress:

```yaml
healthAggregator:
  enabled: true
  ingress:
    enabled: true
    path: /region-healthz
    healthCheckPath: /healthz
```
