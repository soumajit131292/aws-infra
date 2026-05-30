"""
Step 3: Aurora Global Database failover.

Two modes:
  - managed: rds:FailoverGlobalCluster — reversible, used for planned DR drills
             when both regions are healthy.
  - detach:  rds:RemoveFromGlobalCluster — irreversible, used for real disasters
             when the primary region is unreachable.

After the API call, polls until prod-dr cluster is the writer (managed) or is
no longer a member of the global cluster (detach).

Environment:
  SOURCE_REGION         eu-west-1
  DR_REGION             eu-central-1
  GLOBAL_CLUSTER_ID     prod-accesshub-global
  DR_CLUSTER_ARN        arn:aws:rds:eu-central-1:...:cluster:prod-dr-aurora-postgres
  POLL_TIMEOUT_SECONDS  300
"""
import json
import os
import time
import boto3


def _wait_for_writer(rds_src, target_arn, timeout):
    """Poll global cluster until target is writer."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        resp = rds_src.describe_global_clusters(
            GlobalClusterIdentifier=os.environ["GLOBAL_CLUSTER_ID"]
        )
        members = resp["GlobalClusters"][0].get("GlobalClusterMembers", [])
        for m in members:
            if m["DBClusterArn"] == target_arn and m.get("IsWriter"):
                return True
        time.sleep(10)
    return False


def _wait_for_removal(rds_src, target_arn, timeout):
    """Poll until target is no longer in the global cluster."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            resp = rds_src.describe_global_clusters(
                GlobalClusterIdentifier=os.environ["GLOBAL_CLUSTER_ID"]
            )
            members = resp["GlobalClusters"][0].get("GlobalClusterMembers", [])
            if not any(m["DBClusterArn"] == target_arn for m in members):
                return True
        except rds_src.exceptions.GlobalClusterNotFoundFault:
            # If global cluster has no members left, it can be auto-deleted
            return True
        time.sleep(10)
    return False


def lambda_handler(event, context):
    print(f"[aurora] input event: {json.dumps(event)}")
    dry_run = bool(event.get("dry_run", False))
    mode = event.get("mode", "managed")
    if mode not in ("managed", "detach"):
        raise ValueError(f"Invalid mode '{mode}'. Use 'managed' or 'detach'.")

    src_region = os.environ["SOURCE_REGION"]
    dr_region = os.environ["DR_REGION"]
    global_id = os.environ["GLOBAL_CLUSTER_ID"]
    dr_arn = os.environ["DR_CLUSTER_ARN"]
    timeout = int(os.environ.get("POLL_TIMEOUT_SECONDS", "300"))

    if dry_run:
        return {
            "status": "dry-run",
            "mode": mode,
            "would_call": (
                "rds.failover_global_cluster" if mode == "managed"
                else "rds.remove_from_global_cluster"
            ),
            "global_cluster": global_id,
            "target": dr_arn,
        }

    if mode == "managed":
        # Use the primary region's RDS endpoint to control the global cluster.
        rds = boto3.client("rds", region_name=src_region)
        try:
            rds.failover_global_cluster(
                GlobalClusterIdentifier=global_id,
                TargetDbClusterIdentifier=dr_arn,
            )
        except Exception as e:
            raise RuntimeError(f"failover_global_cluster failed: {e}")
        if not _wait_for_writer(rds, dr_arn, timeout):
            raise RuntimeError(
                f"Timed out after {timeout}s waiting for {dr_arn} to become writer"
            )
        return {
            "status": "success",
            "mode": "managed",
            "new_writer_arn": dr_arn,
        }
    else:
        # Detach: prod region is unreachable, call from DR region.
        rds = boto3.client("rds", region_name=dr_region)
        try:
            rds.remove_from_global_cluster(
                GlobalClusterIdentifier=global_id,
                DbClusterIdentifier=dr_arn,
            )
        except Exception as e:
            raise RuntimeError(f"remove_from_global_cluster failed: {e}")
        if not _wait_for_removal(
            boto3.client("rds", region_name=src_region), dr_arn, timeout
        ):
            print("[aurora] warning: could not confirm removal from global cluster "
                  "(prod region may be unreachable, which is expected in detach mode)")
        return {
            "status": "success",
            "mode": "detach",
            "promoted_arn": dr_arn,
            "note": "Cluster is now standalone writable in DR region",
        }
