# Health Aggregator Service

Small HTTP service that checks backend health endpoints in parallel and returns one unified status.

## Endpoints

- `GET /healthz`
- `GET /readyz` (same behavior as `/healthz`)

## Health decision logic

- If any configured **critical** service is down, aggregator returns `500` with `{"status":"DOWN"}`.
- If all critical services are up, aggregator returns `200` with `{"status":"UP"}`.
- Non-critical service failures are included in detail output but do not fail overall status.

## Environment variables

- `SERVICES` (required)
  - Format: `name:url,name:url`
  - Example:
    `ahschedular:http://accesshub-accesshub-ahschedular:8070/actuator/health,adminsvc:http://accesshub-accesshub-adminsvc:8107/actuator/health`
- `CRITICAL_SERVICES` (optional, recommended)
  - Format: comma-separated service names
  - Example: `adminsvc,apponbsvc,loginmodsvc,gatewaysvc,pgmodsvc,scimpersist,ahschedular`
- `CHECK_TIMEOUT_SECONDS` (optional, default `2.5`)
- `MAX_PARALLEL_CHECKS` (optional, default `16`)
- `PORT` (optional, default `8080`)
- `HOST` (optional, default `0.0.0.0`)

## Local run

```bash
export SERVICES="ahschedular:http://localhost:8070/actuator/health,adminsvc:http://localhost:8107/actuator/health,apponbsvc:http://localhost:8108/actuator/health,loginmodsvc:http://localhost:8098/actuator/health,gatewaysvc:http://localhost:8082/actuator/health,pgmodsvc:http://localhost:8095/actuator/health,scimpersist:http://localhost:8091/actuator/health"
export CRITICAL_SERVICES="ahschedular,adminsvc,apponbsvc,loginmodsvc,gatewaysvc,pgmodsvc,scimpersist"
python health-aggregator/app.py
```

Check result:

```bash
curl -s http://localhost:8080/healthz
```

## Docker run

```bash
docker build -t accesshub-health-aggregator:local health-aggregator
docker run --rm -p 8080:8080 \
  -e SERVICES="ahschedular:http://accesshub-accesshub-ahschedular:8070/actuator/health,adminsvc:http://accesshub-accesshub-adminsvc:8107/actuator/health,apponbsvc:http://accesshub-accesshub-apponbsvc:8108/actuator/health,loginmodsvc:http://accesshub-accesshub-loginmodsvc:8098/actuator/health,gatewaysvc:http://accesshub-accesshub-gatewaysvc:8082/actuator/health,pgmodsvc:http://accesshub-accesshub-pgmodsvc:8095/actuator/health,scimpersist:http://accesshub-accesshub-scimpersist:8091/actuator/health" \
  -e CRITICAL_SERVICES="ahschedular,adminsvc,apponbsvc,loginmodsvc,gatewaysvc,pgmodsvc,scimpersist" \
  accesshub-health-aggregator:local
```

## Kubernetes deploy

1) Build and push image to your ECR repo.

2) Update image value in `health-aggregator/k8s.yaml`:

`<your-ecr-repo>/accesshub-health-aggregator:<tag>`

3) Apply resources:

```bash
kubectl apply -f health-aggregator/k8s.yaml
```

4) Verify:

```bash
kubectl get deploy -n accesshub accesshub-health-aggregator
kubectl get svc -n accesshub accesshub-health-aggregator
kubectl port-forward -n accesshub svc/accesshub-health-aggregator 8080:80
curl -s http://localhost:8080/healthz
```

## CI/CD behavior

- Build pipeline is decoupled from application matrix builds.
- Dedicated workflow: `.github/workflows/build-health-aggregator.yml`
- Triggered only when files under `health-aggregator/**` change (or manual dispatch).
- Workflow updates only `healthAggregator.image.digest` in `helm/accesshub/values-dev.yaml`.
- Helm deployment is optional and controlled by `healthAggregator.enabled`.
  - Keep it `false` to avoid deployment.
  - Set it `true` once you want ArgoCD to deploy/track the service.

## Sample responses

Healthy:

```json
{
  "status": "UP",
  "failedCritical": [],
  "services": {}
}
```

Unhealthy:

```json
{
  "status": "DOWN",
  "failedCritical": ["gatewaysvc", "loginmodsvc"],
  "services": {}
}
```
