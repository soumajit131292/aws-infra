"""
Step 6: Scale up prod-dr — first the node group, then the app replicas.

Two phases:
  Phase A: Bump the EKS managed node group's desired_size 0 -> target_size
           and poll until status returns to ACTIVE.
  Phase B: Use the GitHub Contents API to commit values-prod-dr.yaml with
           the new replicaCount. ArgoCD will pick up the commit and scale pods.

Environment:
  DR_REGION              eu-central-1
  DR_CLUSTER_NAME        prod-dr-accesshub-cluster
  DR_NODEGROUP_NAME      core-ng
  TARGET_NODE_DESIRED    3
  TARGET_NODE_MAX        5
  GITHUB_PAT_SECRET_ARN  arn:aws:secretsmanager:...:secret:prod-dr/github-pat-XXX
  GITHUB_OWNER           soumajit131292
  GITHUB_REPO            aws-infra
  GITHUB_BRANCH          main
  GITHUB_VALUES_PATH     helm-charts/helm/accesshub/values-prod-dr.yaml
  POLL_TIMEOUT_SECONDS   600
"""
import base64
import json
import os
import re
import time
import urllib.error
import urllib.request

import boto3


def _scale_nodegroup(eks, cluster, ng, desired, max_size, timeout):
    """Phase A — bump desired_size and wait for status=ACTIVE."""
    print(f"[eks] updating node group {ng}: desired={desired}, max={max_size}")
    eks.update_nodegroup_config(
        clusterName=cluster,
        nodegroupName=ng,
        scalingConfig={
            "minSize": 1,
            "desiredSize": desired,
            "maxSize": max_size,
        },
    )

    deadline = time.time() + timeout
    while time.time() < deadline:
        resp = eks.describe_nodegroup(clusterName=cluster, nodegroupName=ng)
        status = resp["nodegroup"]["status"]
        if status == "ACTIVE":
            return True
        print(f"[eks] nodegroup status={status}, waiting...")
        time.sleep(15)
    return False


def _github_get(url, token):
    req = urllib.request.Request(url, method="GET", headers={
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    })
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def _github_put(url, token, payload):
    req = urllib.request.Request(
        url, method="PUT", data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def _update_replicacount_in_values(content_b64, target_replicas):
    """Decode base64 -> regex-replace replicaCount -> base64 encode."""
    text = base64.b64decode(content_b64).decode("utf-8")
    # Match `replicaCount: <digit>` at start of line (any indentation).
    # If there's NO replicaCount line, we don't add one — that's a bug to fix in helm chart.
    new_text, count = re.subn(
        r"^(\s*replicaCount:\s*)\d+", lambda m: f"{m.group(1)}{target_replicas}",
        text, flags=re.MULTILINE,
    )
    if count == 0:
        raise RuntimeError(
            "No 'replicaCount:' line found in values file — cannot scale via GitOps"
        )
    print(f"[git] replaced {count} replicaCount occurrence(s) -> {target_replicas}")
    return base64.b64encode(new_text.encode("utf-8")).decode("ascii")


def _commit_replica_change(target_replicas):
    """Phase B — GitHub Contents API: read, modify, write the values file."""
    sm = boto3.client("secretsmanager", region_name=os.environ["DR_REGION"])
    secret = sm.get_secret_value(SecretId=os.environ["GITHUB_PAT_SECRET_ARN"])
    token = secret["SecretString"].strip()
    # If secret is JSON, expect {"token":"..."}; else treat as raw token string.
    if token.startswith("{"):
        token = json.loads(token).get("token", token)

    owner = os.environ["GITHUB_OWNER"]
    repo = os.environ["GITHUB_REPO"]
    branch = os.environ["GITHUB_BRANCH"]
    path = os.environ["GITHUB_VALUES_PATH"]

    api = f"https://api.github.com/repos/{owner}/{repo}/contents/{path}"

    print(f"[git] fetching {api}?ref={branch}")
    current = _github_get(f"{api}?ref={branch}", token)
    sha = current["sha"]

    new_b64 = _update_replicacount_in_values(current["content"], target_replicas)

    payload = {
        "message": f"DR failover: scale prod-dr replicaCount to {target_replicas}",
        "content": new_b64,
        "sha": sha,
        "branch": branch,
    }
    print(f"[git] committing to {owner}/{repo}@{branch} {path}")
    resp = _github_put(api, token, payload)
    return resp.get("commit", {}).get("sha")


def lambda_handler(event, context):
    print(f"[eks_scale] input event: {json.dumps(event)}")
    dry_run = bool(event.get("dry_run", False))

    cluster = os.environ["DR_CLUSTER_NAME"]
    ng = os.environ["DR_NODEGROUP_NAME"]
    desired = int(event.get("target_node_desired",
                            os.environ.get("TARGET_NODE_DESIRED", "3")))
    max_size = int(os.environ.get("TARGET_NODE_MAX", "5"))
    replicas = int(event.get("target_replicas", desired))
    timeout = int(os.environ.get("POLL_TIMEOUT_SECONDS", "600"))

    if dry_run:
        return {
            "status": "dry-run",
            "nodegroup": ng,
            "would_scale_nodes_to": desired,
            "would_commit_replicas": replicas,
        }

    eks = boto3.client("eks", region_name=os.environ["DR_REGION"])

    # Phase A: scale node group
    if not _scale_nodegroup(eks, cluster, ng, desired, max_size, timeout):
        raise RuntimeError(
            f"Timed out after {timeout}s waiting for node group {ng} to become ACTIVE"
        )

    # Phase B: commit replica change to git
    commit_sha = _commit_replica_change(replicas)

    return {
        "status": "success",
        "nodegroup": ng,
        "node_desired": desired,
        "replica_count": replicas,
        "commit_sha": commit_sha,
        "note": "ArgoCD will reconcile within its sync interval (default 3 min)",
    }
