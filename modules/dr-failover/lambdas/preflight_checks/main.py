"""
Step 1: Pre-flight checks before DR failover.

Validates that the DR environment is actually ready to take over. Returns
detailed status of each check. If any required check fails, Step Functions
aborts the run.

Environment variables:
  SOURCE_REGION              eu-west-1
  DR_REGION                  eu-central-1
  GLOBAL_CLUSTER_ID          prod-accesshub-global
  DR_CLUSTER_ARN             arn:aws:rds:eu-central-1:...:cluster:prod-dr-...
  SOURCE_EFS_ID              fs-xxxxx (prod)
  DR_EFS_ID                  fs-yyyyy (prod-dr destination)
  DR_EKS_CLUSTER_NAME        prod-dr-accesshub-cluster
  DR_PRIVATE_HOSTED_ZONE_ID  Zxxxxx
  MAX_REPLICATION_LAG_SEC    60
"""
import json
import os
import boto3
from datetime import datetime, timezone


def _global_cluster_ok(rds_src):
    """Aurora Global Cluster present, prod is writer, prod-dr is reader."""
    try:
        resp = rds_src.describe_global_clusters(
            GlobalClusterIdentifier=os.environ["GLOBAL_CLUSTER_ID"]
        )
        gc = resp["GlobalClusters"][0]
        if gc["Status"] != "available":
            return False, f"Global cluster status={gc['Status']}, expected available"
        members = gc.get("GlobalClusterMembers", [])
        if len(members) != 2:
            return False, f"Expected 2 members, found {len(members)}"
        writers = [m for m in members if m.get("IsWriter")]
        if len(writers) != 1:
            return False, f"Expected exactly 1 writer, found {len(writers)}"
        dr_member = next(
            (m for m in members
             if m["DBClusterArn"] == os.environ["DR_CLUSTER_ARN"]), None
        )
        if dr_member is None:
            return False, "Prod-DR cluster not a member of global cluster"
        if dr_member.get("IsWriter"):
            return False, "Prod-DR is already the writer — failover may already be complete"
        return True, "Global cluster healthy; prod-dr is read-only secondary"
    except Exception as e:
        return False, f"describe_global_clusters failed: {e}"


def _efs_replication_ok(efs_src):
    """EFS replication is ENABLED and lag is acceptable."""
    try:
        resp = efs_src.describe_replication_configurations(
            FileSystemId=os.environ["SOURCE_EFS_ID"]
        )
        repls = resp.get("Replications", [])
        if not repls:
            return False, "No replication configuration found on source EFS"
        dest = repls[0]["Destinations"][0]
        status = dest.get("Status")
        if status != "ENABLED":
            return False, f"Replication status={status}, expected ENABLED"
        last_ts = dest.get("LastReplicatedTimestamp")
        if last_ts:
            lag_seconds = (datetime.now(timezone.utc) - last_ts).total_seconds()
            max_lag = int(os.environ.get("MAX_REPLICATION_LAG_SEC", "60"))
            if lag_seconds > max_lag:
                return False, f"Replication lag {lag_seconds:.0f}s exceeds {max_lag}s"
            return True, f"Replication ENABLED, lag {lag_seconds:.0f}s"
        return True, "Replication ENABLED, no lag data yet"
    except Exception as e:
        return False, f"describe_replication_configurations failed: {e}"


def _eks_cluster_ok(eks_dr):
    """Prod-DR EKS API is reachable and cluster is ACTIVE."""
    try:
        resp = eks_dr.describe_cluster(name=os.environ["DR_EKS_CLUSTER_NAME"])
        status = resp["cluster"]["status"]
        if status != "ACTIVE":
            return False, f"EKS cluster status={status}, expected ACTIVE"
        return True, f"EKS cluster ACTIVE (endpoint={resp['cluster']['endpoint']})"
    except Exception as e:
        return False, f"describe_cluster failed: {e}"


def _route53_zone_ok(r53):
    """Prod-DR private hosted zone exists and is reachable."""
    try:
        zone_id = os.environ["DR_PRIVATE_HOSTED_ZONE_ID"]
        resp = r53.get_hosted_zone(Id=zone_id)
        return True, f"Private hosted zone {resp['HostedZone']['Name']} OK"
    except Exception as e:
        return False, f"get_hosted_zone failed: {e}"


def lambda_handler(event, context):
    print(f"[preflight] input event: {json.dumps(event)}")
    dry_run = bool(event.get("dry_run", False))

    src_region = os.environ["SOURCE_REGION"]
    dr_region = os.environ["DR_REGION"]

    rds_src = boto3.client("rds", region_name=src_region)
    efs_src = boto3.client("efs", region_name=src_region)
    eks_dr = boto3.client("eks", region_name=dr_region)
    r53 = boto3.client("route53")  # Route 53 is global

    checks = {
        "global_cluster":  _global_cluster_ok(rds_src),
        "efs_replication": _efs_replication_ok(efs_src),
        "dr_eks_cluster":  _eks_cluster_ok(eks_dr),
        "dr_route53_zone": _route53_zone_ok(r53),
    }
    results = {name: {"ok": ok, "detail": detail}
               for name, (ok, detail) in checks.items()}

    all_ok = all(r["ok"] for r in results.values())

    body = {
        "status": "ok" if all_ok else "failed",
        "dry_run": dry_run,
        "results": results,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    print(f"[preflight] {json.dumps(body, indent=2)}")

    if not all_ok and not dry_run:
        raise RuntimeError(
            f"Pre-flight failed: " + "; ".join(
                f"{k}={v['detail']}" for k, v in results.items() if not v["ok"]
            )
        )
    return body
