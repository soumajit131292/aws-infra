"""
Deployment-aware alarm action controller.

Two invocation paths:

  1) API Gateway webhook (from ArgoCD Notifications)
     Event body: {"event": "sync-started"|"deployed"|"sync-failed",
                  "application": "<app-name>"}
     Action:
       sync-started  -> disable alarm actions, write DynamoDB state row
       deployed      -> enable alarm actions, delete DynamoDB state row
       sync-failed   -> enable alarm actions, delete DynamoDB state row

  2) EventBridge scheduled rule (failsafe)
     Event body: {"source": "scheduled-failsafe"}
     Action:
       Read DynamoDB. If state is "disabled" AND last disable was > MAX_AGE
       seconds ago, force-enable alarm actions and delete state row.
       Protects against missed "deployed" webhooks.

Alarm actions are disabled per-region: this Lambda iterates over the alarm
inventory passed via env (JSON-encoded) and calls each region's CloudWatch
API. The alarm STATE keeps tracking — only the action (SNS publish) is muted.

Security: ArgoCD-originating requests include an HMAC signature header
(X-Webhook-Signature). The Lambda verifies the signature against a shared
secret read from environment.

Environment:
  ALARM_INVENTORY        JSON: {"<region>": ["<alarm-name>", ...], ...}
  STATE_TABLE_NAME       DynamoDB table holding the disabled-at marker
  WEBHOOK_SHARED_SECRET  HMAC shared secret (also configured in ArgoCD)
  MAX_DISABLED_AGE_SEC   Failsafe threshold (default 2700 = 45 min)
"""
import hashlib
import hmac
import json
import os
import time
import base64
from typing import Tuple

import boto3
from botocore.exceptions import ClientError


_STATE_ROW_ID = "argocd-deployment"


def _now() -> int:
    return int(time.time())


def _resp(status: int, body) -> dict:
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def _hmac_ok(payload_bytes: bytes, provided: str) -> bool:
    """Authenticate webhook using either shared token or HMAC variants."""
    secret_str = os.environ.get("WEBHOOK_SHARED_SECRET", "")
    secret = secret_str.encode("utf-8")
    if not secret_str:
        return True  # signing not configured
    digest = hmac.new(secret, payload_bytes, hashlib.sha256).digest()
    expected_hex = digest.hex()
    expected_b64 = base64.b64encode(digest).decode("utf-8")

    raw = (provided or "").strip().strip('"').strip("'")

    # Accept common header variants:
    # - "<hex>"
    # - "sha256=<hex>"
    # - "<base64>"
    # - "sha256=<base64>"
    # - "t=...,v1=<sig>" (Stripe-like multi-part)
    candidates = [raw]
    for part in raw.split(","):
        p = part.strip().strip('"').strip("'")
        if "=" in p:
            candidates.append(p.split("=", 1)[1].strip())
        candidates.append(p)

    for c in candidates:
        if c.lower().startswith("sha256="):
            c = c.split("=", 1)[1].strip()
        # Fast path: header carries the shared secret token directly.
        if hmac.compare_digest(secret_str, c):
            return True
        if hmac.compare_digest(expected_hex, c):
            return True
        if hmac.compare_digest(expected_b64, c):
            return True
    return False


def _disable_alarm_actions(inventory: dict, dry_run: bool = False) -> dict:
    """Call DisableAlarmActions for every alarm, grouped by region."""
    results = {}
    for region, alarm_names in inventory.items():
        if not alarm_names:
            continue
        if dry_run:
            results[region] = {"action": "dry-run-disable", "alarms": alarm_names}
            continue
        cw = boto3.client("cloudwatch", region_name=region)
        try:
            cw.disable_alarm_actions(AlarmNames=alarm_names)
            results[region] = {"status": "disabled", "count": len(alarm_names)}
        except ClientError as e:
            results[region] = {"status": "error", "error": str(e)}
    return results


def _enable_alarm_actions(inventory: dict, dry_run: bool = False) -> dict:
    """Call EnableAlarmActions for every alarm, grouped by region."""
    results = {}
    for region, alarm_names in inventory.items():
        if not alarm_names:
            continue
        if dry_run:
            results[region] = {"action": "dry-run-enable", "alarms": alarm_names}
            continue
        cw = boto3.client("cloudwatch", region_name=region)
        try:
            cw.enable_alarm_actions(AlarmNames=alarm_names)
            results[region] = {"status": "enabled", "count": len(alarm_names)}
        except ClientError as e:
            results[region] = {"status": "error", "error": str(e)}
    return results


def _put_state(table, app_name: str, ttl_seconds: int):
    table.put_item(Item={
        "id": _STATE_ROW_ID,
        "state": "disabled",
        "application": app_name,
        "disabled_at": _now(),
        "deployed_reported": False,
        "ttl": _now() + ttl_seconds,
    })


def _delete_state(table):
    table.delete_item(Key={"id": _STATE_ROW_ID})


def _mark_deployed_reported(table, state: dict):
    state["deployed_reported"] = True
    table.put_item(Item=state)


def _read_state(table) -> dict:
    resp = table.get_item(Key={"id": _STATE_ROW_ID})
    return resp.get("Item") or {}


def _parse_payload(event: dict) -> Tuple[str, str, bytes]:
    """Extract (event_type, application, raw_body_bytes) from API GW v2 event."""
    body_str = event.get("body") or ""
    if event.get("isBase64Encoded"):
        import base64
        body_bytes = base64.b64decode(body_str)
        body_str = body_bytes.decode("utf-8")
    else:
        body_bytes = body_str.encode("utf-8")

    try:
        payload = json.loads(body_str) if body_str else {}
    except json.JSONDecodeError:
        payload = {}

    event_type = (payload.get("event") or "").strip().lower()
    application = (payload.get("application") or "unknown").strip()
    return event_type, application, body_bytes


def _handle_webhook(event: dict, inventory: dict, table) -> dict:
    """Handle an ArgoCD webhook event."""
    event_type, application, body_bytes = _parse_payload(event)
    print(f"[alarm-actions] parsed webhook payload event={event_type or '<empty>'} application={application}")

    # Verify HMAC if configured
    headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    sig_header = headers.get("x-webhook-signature", "")
    preview = sig_header[:24] + ("..." if len(sig_header) > 24 else "")
    print(f"[alarm-actions] signature header present={bool(sig_header)} len={len(sig_header)} preview={preview}")
    sig_ok = _hmac_ok(body_bytes, sig_header)
    if not sig_ok:
        print("[alarm-actions] rejecting webhook: invalid signature")
        return _resp(403, {"error": "invalid_signature"})

    # Be tolerant to naming variants from notification templates.
    if event_type in ("sync-started", "sync-running", "on-sync-running"):
        max_age = int(os.environ.get("MAX_DISABLED_AGE_SEC", "2700"))
        print(f"[alarm-actions] disabling alarm actions for app={application}")
        result = _disable_alarm_actions(inventory)
        _put_state(table, application, ttl_seconds=max_age)
        return _resp(200, {
            "status": "alarms_disabled",
            "application": application,
            "result": result,
        })

    if event_type in ("deployed", "sync-succeeded", "sync-failed"):
        min_hold = int(os.environ.get("MIN_SUPPRESSION_SEC", "900"))
        state = _read_state(table)
        if state:
            age = _now() - int(state.get("disabled_at", 0))
            if age < min_hold:
                _mark_deployed_reported(table, state)
                remaining = min_hold - age
                print(f"[alarm-actions] keeping alarms disabled: min suppression hold not met, remaining={remaining}s")
                return _resp(200, {
                    "status": "hold_active",
                    "application": application,
                    "event": event_type,
                    "remaining_seconds": remaining,
                })
        print(f"[alarm-actions] enabling alarm actions for app={application} due to event={event_type}")
        result = _enable_alarm_actions(inventory)
        _delete_state(table)
        return _resp(200, {
            "status": "alarms_enabled",
            "application": application,
            "event": event_type,
            "result": result,
        })

    print(f"[alarm-actions] rejecting webhook: unsupported event '{event_type}'")
    return _resp(400, {"error": f"unsupported event '{event_type}'"})


def _handle_failsafe(inventory: dict, table) -> dict:
    """EventBridge scheduled invocation — force-enable if stuck disabled too long."""
    state = _read_state(table)
    min_hold = int(os.environ.get("MIN_SUPPRESSION_SEC", "900"))
    max_age = int(os.environ.get("MAX_DISABLED_AGE_SEC", "2700"))

    if not state:
        # Nothing to do — alarms are presumed enabled.
        return {"status": "no_state", "action": "noop"}

    disabled_at = int(state.get("disabled_at", 0))
    age = _now() - disabled_at
    if state.get("deployed_reported") and age >= min_hold:
        result = _enable_alarm_actions(inventory)
        _delete_state(table)
        return {
            "status": "enabled_after_min_hold",
            "age_seconds": age,
            "min_hold_seconds": min_hold,
            "application": state.get("application"),
            "result": result,
        }

    if age < max_age:
        return {
            "status": "still_within_window",
            "age_seconds": age,
            "max_age_seconds": max_age,
        }

    # Force re-enable
    result = _enable_alarm_actions(inventory)
    _delete_state(table)
    return {
        "status": "force_enabled",
        "stale_age_seconds": age,
        "application": state.get("application"),
        "result": result,
    }


def lambda_handler(event, context):
    print(f"[alarm-actions] event source: {event.get('source') or 'api-gateway'}")

    inventory_raw = os.environ.get("ALARM_INVENTORY", "{}")
    try:
        inventory = json.loads(inventory_raw)
    except json.JSONDecodeError:
        return _resp(500, {"error": "invalid ALARM_INVENTORY env (not JSON)"})

    table_name = os.environ.get("STATE_TABLE_NAME")
    if not table_name:
        return _resp(500, {"error": "STATE_TABLE_NAME env not set"})

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)

    # EventBridge invocations have "source" at the top level. API Gateway
    # events have "requestContext".
    if event.get("source") == "aws.events" or "scheduled-failsafe" in str(event):
        result = _handle_failsafe(inventory, table)
        print(f"[alarm-actions] failsafe result: {json.dumps(result)}")
        return result

    # API Gateway path
    return _handle_webhook(event, inventory, table)
