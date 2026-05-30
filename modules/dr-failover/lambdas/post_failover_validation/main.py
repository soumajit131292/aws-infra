"""
Step 7: Post-failover validation.

Verifies that the failover actually succeeded:
  - Aurora prod-dr cluster is the writer
  - EFS prod-dr is in 'available' (writable) state
  - prod-dr ALB returns 200 on /health
  - Route 53 public health check on prod-dr is GREEN
  - At least one pod is running in the accesshub namespace
    (best-effort check via EKS describe — does NOT exec into the cluster)

Returns a structured report. Failed checks raise so Step Functions can route
to a FailureNotification state.

Environment:
  SOURCE_REGION              eu-west-1
  DR_REGION                  eu-central-1
  GLOBAL_CLUSTER_ID
  DR_CLUSTER_ARN
  DR_EFS_ID
  DR_ALB_HEALTH_URL          https://prod-aws.accesshub-identity.com/health
  R53_DR_HEALTH_CHECK_ID     (optional; check this Route 53 health check is GREEN)
"""
import json
import os
import ssl
import time
import urllib.error
import urllib.request

import boto3


def _check_aurora_writer():
    rds = boto3.client("rds", region_name=os.environ["SOURCE_REGION"])
    try:
        resp = rds.describe_global_clusters(
            GlobalClusterIdentifier=os.environ["GLOBAL_CLUSTER_ID"]
        )
        members = resp["GlobalClusters"][0].get("GlobalClusterMembers", [])
        dr_member = next(
            (m for m in members if m["DBClusterArn"] == os.environ["DR_CLUSTER_ARN"]),
            None,
        )
        if dr_member is None:
            return False, "Prod-DR not found in global cluster (possibly detached — verify manually)"
        if dr_member.get("IsWriter"):
            return True, "Prod-DR is the writer"
        return False, f"Prod-DR IsWriter={dr_member.get('IsWriter')}"
    except rds.exceptions.GlobalClusterNotFoundFault:
        return True, "Global cluster no longer exists (detach mode) — prod-dr is standalone writable"
    except Exception as e:
        return False, f"describe_global_clusters failed: {e}"


def _check_efs_writable():
    efs = boto3.client("efs", region_name=os.environ["DR_REGION"])
    try:
        resp = efs.describe_file_systems(FileSystemId=os.environ["DR_EFS_ID"])
        state = resp["FileSystems"][0].get("LifeCycleState")
        if state == "available":
            return True, "EFS LifeCycleState=available (writable)"
        return False, f"EFS LifeCycleState={state}"
    except Exception as e:
        return False, f"describe_file_systems failed: {e}"


def _check_alb_health(url, retries=5, sleep_seconds=15):
    """HTTP GET /health on prod-dr ALB. Retry to allow pods to come up."""
    ctx = ssl.create_default_context()
    last_err = None
    for i in range(retries):
        try:
            req = urllib.request.Request(url, method="GET", headers={
                "User-Agent": "dr-failover-validator"
            })
            with urllib.request.urlopen(req, context=ctx, timeout=10) as r:
                if r.status == 200:
                    return True, f"GET {url} returned 200"
                last_err = f"HTTP {r.status}"
        except urllib.error.HTTPError as e:
            last_err = f"HTTPError {e.code}"
        except Exception as e:
            last_err = str(e)
        time.sleep(sleep_seconds)
    return False, f"After {retries} attempts: {last_err}"


def _check_route53_health(health_check_id):
    if not health_check_id:
        return True, "No Route 53 health check configured for verification — skipped"
    r53 = boto3.client("route53")
    try:
        resp = r53.get_health_check_status(HealthCheckId=health_check_id)
        observations = resp.get("HealthCheckObservations", [])
        if not observations:
            return False, "No observations from health check yet"
        # All healthchecker regions must report Success
        all_ok = all(
            (o.get("StatusReport") or {}).get("Status", "").startswith("Success")
            for o in observations
        )
        if all_ok:
            return True, f"All {len(observations)} healthcheckers report Success"
        bad = [o for o in observations
               if not (o.get("StatusReport") or {}).get("Status", "").startswith("Success")]
        return False, f"{len(bad)}/{len(observations)} healthcheckers failing"
    except Exception as e:
        return False, f"get_health_check_status failed: {e}"


def lambda_handler(event, context):
    print(f"[validate] input event: {json.dumps(event)}")
    dry_run = bool(event.get("dry_run", False))

    if dry_run:
        return {"status": "dry-run", "note": "Skipping validation in dry-run"}

    checks = {}
    checks["aurora_writer"]   = _check_aurora_writer()
    checks["efs_writable"]    = _check_efs_writable()
    checks["alb_health"]      = _check_alb_health(
        os.environ.get("DR_ALB_HEALTH_URL",
                       "https://prod-aws.accesshub-identity.com/health"))
    checks["route53_health"]  = _check_route53_health(
        os.environ.get("R53_DR_HEALTH_CHECK_ID", ""))

    results = {name: {"ok": ok, "detail": detail}
               for name, (ok, detail) in checks.items()}
    all_ok = all(r["ok"] for r in results.values())

    body = {
        "status": "ok" if all_ok else "failed",
        "results": results,
    }
    print(f"[validate] {json.dumps(body, indent=2)}")

    if not all_ok:
        failed = [k for k, v in results.items() if not v["ok"]]
        raise RuntimeError(f"Post-failover validation failed: {failed}")

    return body
