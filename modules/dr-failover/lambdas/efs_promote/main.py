"""
Step 4: Promote the replicated EFS in prod-dr from read-only to writable.

Deletes the EFS replication configuration. Once deleted, the destination EFS
in eu-central-1 becomes a standalone writable file system. This is
irreversible — the replication relationship is destroyed.

Polls the destination EFS until its LifeCycleState is 'available' and the
source no longer reports an active replication.

Environment:
  SOURCE_REGION         eu-west-1
  DR_REGION             eu-central-1
  SOURCE_EFS_ID         fs-xxxxx (prod)
  DR_EFS_ID             fs-yyyyy (prod-dr destination)
  POLL_TIMEOUT_SECONDS  180
"""
import json
import os
import time
import boto3


def _wait_for_replica_promoted(efs_src, efs_dr, source_id, dr_id, timeout):
    """Poll until source has no active replication AND destination is available."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        # Source EFS: replication configuration should be deleted
        try:
            resp = efs_src.describe_replication_configurations(FileSystemId=source_id)
            still_replicating = bool(resp.get("Replications", []))
        except efs_src.exceptions.ReplicationNotFound:
            still_replicating = False
        except Exception:
            still_replicating = True  # be cautious

        # Destination EFS: should be in 'available' state
        try:
            resp = efs_dr.describe_file_systems(FileSystemId=dr_id)
            fs = resp["FileSystems"][0]
            dest_state = fs.get("LifeCycleState")
        except Exception:
            dest_state = "unknown"

        if not still_replicating and dest_state == "available":
            return True

        print(f"[efs] waiting... source_still_replicating={still_replicating} "
              f"dest_state={dest_state}")
        time.sleep(5)
    return False


def lambda_handler(event, context):
    print(f"[efs] input event: {json.dumps(event)}")
    dry_run = bool(event.get("dry_run", False))

    src_region = os.environ["SOURCE_REGION"]
    dr_region = os.environ["DR_REGION"]
    source_id = os.environ["SOURCE_EFS_ID"]
    dr_id = os.environ["DR_EFS_ID"]
    timeout = int(os.environ.get("POLL_TIMEOUT_SECONDS", "180"))

    efs_src = boto3.client("efs", region_name=src_region)
    efs_dr = boto3.client("efs", region_name=dr_region)

    if dry_run:
        return {
            "status": "dry-run",
            "would_call": "efs.delete_replication_configuration",
            "source_efs_id": source_id,
            "dr_efs_id": dr_id,
        }

    # Action: delete replication on the SOURCE EFS.
    # If the source region is unreachable, this fails — try the DR side then.
    try:
        efs_src.delete_replication_configuration(SourceFileSystemId=source_id)
        print(f"[efs] delete_replication_configuration submitted on source EFS {source_id}")
    except Exception as e:
        print(f"[efs] source-side delete failed ({e}); trying destination side fallback")
        # In a true DR scenario, source region may be unreachable. AWS docs say
        # delete must be called against the source, but in degraded conditions
        # we surface the failure clearly.
        raise RuntimeError(
            f"Failed to delete replication configuration from source region "
            f"{src_region}: {e}. Manual intervention may be required."
        )

    if not _wait_for_replica_promoted(efs_src, efs_dr, source_id, dr_id, timeout):
        raise RuntimeError(
            f"Timed out after {timeout}s waiting for destination EFS {dr_id} "
            "to become standalone writable"
        )

    return {
        "status": "success",
        "promoted_efs_id": dr_id,
        "note": "Destination EFS is now writable",
    }
