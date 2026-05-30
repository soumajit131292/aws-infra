"""
Step 5: Flip the private hosted zone's db.accesshub.internal CNAME so apps in
prod-dr resolve to the local (now-writable) RDS Proxy.

Updates the rds_active record in the prod-dr private hosted zone to point at
the rds_dr record (which itself CNAMEs to the prod-dr RDS Proxy endpoint).

Environment:
  DR_PRIVATE_HOSTED_ZONE_ID   Zxxx (private zone in prod-dr VPC)
  RDS_ACTIVE_RECORD_NAME      db.accesshub.internal
  RDS_DR_RECORD_NAME          db-dr.accesshub.internal
  RECORD_TTL                  60
"""
import json
import os
import time
import boto3


def _change_record(r53, zone_id, name, target, ttl):
    """UPSERT a CNAME record."""
    return r53.change_resource_record_sets(
        HostedZoneId=zone_id,
        ChangeBatch={
            "Comment": "DR failover: re-targeting app-facing DB CNAME to DR",
            "Changes": [{
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": name,
                    "Type": "CNAME",
                    "TTL": ttl,
                    "ResourceRecords": [{"Value": target}],
                },
            }],
        },
    )


def _wait_for_change(r53, change_id, timeout=120):
    deadline = time.time() + timeout
    while time.time() < deadline:
        resp = r53.get_change(Id=change_id)
        if resp["ChangeInfo"]["Status"] == "INSYNC":
            return True
        time.sleep(5)
    return False


def lambda_handler(event, context):
    print(f"[dns] input event: {json.dumps(event)}")
    dry_run = bool(event.get("dry_run", False))

    zone_id = os.environ["DR_PRIVATE_HOSTED_ZONE_ID"]
    active_name = os.environ["RDS_ACTIVE_RECORD_NAME"]
    dr_target = os.environ["RDS_DR_RECORD_NAME"]
    ttl = int(os.environ.get("RECORD_TTL", "60"))

    if dry_run:
        return {
            "status": "dry-run",
            "would_call": "route53.change_resource_record_sets",
            "zone_id": zone_id,
            "record": active_name,
            "new_target": dr_target,
        }

    r53 = boto3.client("route53")
    try:
        resp = _change_record(r53, zone_id, active_name, dr_target, ttl)
        change_id = resp["ChangeInfo"]["Id"]
        print(f"[dns] change submitted: {change_id}")
    except Exception as e:
        raise RuntimeError(f"change_resource_record_sets failed: {e}")

    if not _wait_for_change(r53, change_id):
        # Don't hard-fail — change submitted, propagation in progress
        print("[dns] warning: change not yet INSYNC after 120s, but submitted")

    return {
        "status": "success",
        "zone_id": zone_id,
        "record": active_name,
        "new_target": dr_target,
        "ttl": ttl,
        "change_id": change_id,
        "note": f"Apps querying {active_name} will resolve to {dr_target} "
                "within {ttl}s (TTL) once their resolver caches expire",
    }
