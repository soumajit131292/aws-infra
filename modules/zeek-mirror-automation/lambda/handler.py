"""
Keep VPC Traffic Mirroring sessions in sync with the live EKS worker nodes.

Every invocation runs a full reconcile (idempotent):
  desired  = ALL attached ENIs of running instances tagged eks:cluster-name=<CLUSTER>
             (primary + secondary -- VPC CNI pod traffic uses secondary ENIs too)
  current  = sessions on the Zeek mirror target that this Lambda manages
  -> create sessions for ENIs that don't have one
  -> delete sessions whose ENI/node is gone

Triggered by EC2 state-change events (node launch/terminate) and by a
scheduled rule (safety net + initial backfill). boto3 ships in the Lambda
runtime, so there are no extra dependencies to bundle.
"""

import logging
import os

import boto3

log = logging.getLogger()
log.setLevel(logging.INFO)

ec2 = boto3.client("ec2")

CLUSTER = os.environ["CLUSTER_NAME"]
TARGET = os.environ["MIRROR_TARGET_ID"]
FILTER = os.environ["MIRROR_FILTER_ID"]
VNI = int(os.environ.get("VNI", "4789"))
MANAGED_TAG = "zeek-mirror-lambda"
MAX_SESSION_NUMBER = 32766


def desired_enis():
    """Return {eni_id: instance_id} for ALL ENIs on running nodes of the cluster.

    EKS with the VPC CNI (and prefix delegation) attaches secondary ENIs to a
    node as pod density grows, and pod traffic flows over those secondary ENIs
    too. So we mirror every ENI attached to each node, not just the primary
    (DeviceIndex 0) -- otherwise pod traffic on secondary ENIs is a blind spot.
    """
    out = {}
    paginator = ec2.get_paginator("describe_instances")
    for page in paginator.paginate(
        Filters=[
            {"Name": "tag:eks:cluster-name", "Values": [CLUSTER]},
            {"Name": "instance-state-name", "Values": ["running"]},
        ]
    ):
        for reservation in page["Reservations"]:
            for inst in reservation["Instances"]:
                for ni in inst.get("NetworkInterfaces", []):
                    # Only mirror interfaces actually attached to the node.
                    if ni.get("Attachment", {}).get("Status") in ("attaching", "attached"):
                        out[ni["NetworkInterfaceId"]] = inst["InstanceId"]
    return out


def current_sessions():
    """Return {eni_id: session_id} for sessions this Lambda manages on the target."""
    out = {}
    paginator = ec2.get_paginator("describe_traffic_mirror_sessions")
    for page in paginator.paginate(
        Filters=[
            {"Name": "traffic-mirror-target-id", "Values": [TARGET]},
            {"Name": "tag:ManagedBy", "Values": [MANAGED_TAG]},
        ]
    ):
        for s in page["TrafficMirrorSessions"]:
            out[s["NetworkInterfaceId"]] = s["TrafficMirrorSessionId"]
    return out


def used_session_numbers():
    """Every session number in use on the target (managed or not)."""
    nums = set()
    paginator = ec2.get_paginator("describe_traffic_mirror_sessions")
    for page in paginator.paginate(
        Filters=[{"Name": "traffic-mirror-target-id", "Values": [TARGET]}]
    ):
        for s in page["TrafficMirrorSessions"]:
            nums.add(s["SessionNumber"])
    return nums


def create_session(eni, instance_id):
    used = used_session_numbers()
    for number in range(1, MAX_SESSION_NUMBER + 1):
        if number in used:
            continue
        try:
            ec2.create_traffic_mirror_session(
                NetworkInterfaceId=eni,
                TrafficMirrorTargetId=TARGET,
                TrafficMirrorFilterId=FILTER,
                SessionNumber=number,
                VirtualNetworkId=VNI,
                TagSpecifications=[
                    {
                        "ResourceType": "traffic-mirror-session",
                        "Tags": [
                            {"Key": "ManagedBy", "Value": MANAGED_TAG},
                            {"Key": "InstanceId", "Value": instance_id},
                            {"Key": "Name", "Value": f"{CLUSTER}-auto-{eni}"},
                        ],
                    }
                ],
            )
            log.info("created mirror session eni=%s instance=%s number=%s", eni, instance_id, number)
            return
        except ec2.exceptions.ClientError as e:
            # Session number raced with another create -> try the next one.
            if "SessionNumber" in str(e) or "Duplicate" in str(e) or "InvalidParameterValue" in str(e):
                used.add(number)
                continue
            raise
    log.error("no free session number available for eni=%s", eni)


def delete_session(session_id):
    ec2.delete_traffic_mirror_session(TrafficMirrorSessionId=session_id)
    log.info("deleted stale mirror session %s", session_id)


def reconcile():
    desired = desired_enis()
    current = current_sessions()

    for eni, instance_id in desired.items():
        if eni not in current:
            create_session(eni, instance_id)

    for eni, session_id in current.items():
        if eni not in desired:
            delete_session(session_id)

    log.info("reconcile done: desired=%d current=%d", len(desired), len(current))


def handler(event, context):  # noqa: ARG001 - Lambda signature
    # Any trigger (node event or schedule) just runs a full idempotent sync.
    reconcile()
    return {"status": "ok"}
