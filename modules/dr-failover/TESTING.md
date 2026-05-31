# DR Failover — Testing Playbook

End-to-end testing guide for the prod-dr failover orchestration. Run these
tests after any change to the dr-failover module, or as part of monthly DR
validation drills.

Tests are organized **lowest-risk → highest-confidence**:

| Level | Risk | Validates |
|-------|------|-----------|
| 1     | Zero | Alarm pipeline (alarms → SNS → email) |
| 2     | Zero | Lambda IAM, read-only logic, approval HMAC |
| 3     | Zero | ArgoCD-driven alarm suppression (Phase 2) |
| 4     | Zero | Full state machine end-to-end via dry-run |
| 5     | Zero | Negative paths (deny, timeout) |

**Cadence:** Run Levels 1, 2, and 4 monthly. Run Level 3 around any planned
ArgoCD deploy. Run Level 5 quarterly.

---

## Prerequisites

### One-time setup
- AWS CLI configured for account `495711089104`
- IAM permissions to: invoke Lambdas, read CloudWatch alarms, run Step
  Functions executions, scan DynamoDB
- Access to inbox subscribed to `dr-alerts` and `dr-complete` SNS topics
- For Level 3: `kubectl` context for prod EKS cluster (eu-west-1)

### Environment setup (run at the top of every test session)

```bash
# Verify identity
aws sts get-caller-identity
# Expected: Account 495711089104

# Set commonly-used variables
export DR_REGION="eu-central-1"
export SRC_REGION="eu-west-1"
export NAME_PREFIX="prod-dr-failover"
export STATE_MACHINE_ARN="arn:aws:states:${DR_REGION}:495711089104:stateMachine:${NAME_PREFIX}-state-machine"
```

---

## Level 1 — Alarm pipeline tests (zero risk)

### 1.1 Confirm all 7 Tier-1 alarms exist and are in OK state

```bash
aws cloudwatch describe-alarms --region $DR_REGION \
  --alarm-name-prefix "${NAME_PREFIX}" \
  --query 'MetricAlarms[*].[AlarmName,StateValue,ActionsEnabled]' \
  --output table

aws cloudwatch describe-alarms --region $SRC_REGION \
  --alarm-name-prefix "${NAME_PREFIX}" \
  --query 'MetricAlarms[*].[AlarmName,StateValue,ActionsEnabled]' \
  --output table

aws cloudwatch describe-alarms --region us-east-1 \
  --alarm-name-prefix "${NAME_PREFIX}" \
  --query 'MetricAlarms[*].[AlarmName,StateValue,ActionsEnabled]' \
  --output table
```

**Expected:** 7 alarms total across the 3 regions, all `OK`, all
`ActionsEnabled=True`.

| Region        | Alarms |
|---------------|--------|
| eu-central-1  | aurora-replication-lag-high, efs-replication-lag-high |
| eu-west-1     | alb-unhealthy-hosts, alb-target-5xx-high, aurora-no-connections, aurora-db-load-high |
| us-east-1     | route53-prod-app-unhealthy |

### 1.2 Confirm the composite alarm exists

```bash
aws cloudwatch describe-alarms --region $DR_REGION \
  --alarm-types CompositeAlarm \
  --query 'CompositeAlarms[*].[AlarmName,StateValue,AlarmRule]' \
  --output table
```

**Expected:** `prod-dr-failover-COMPOSITE-cross-region-replication-degraded`
in `OK` state with rule
`ALARM(...aurora-replication-lag-high) AND ALARM(...efs-replication-lag-high)`.

### 1.3 Trigger a single alarm and verify email delivery

```bash
aws cloudwatch set-alarm-state --region $DR_REGION \
  --alarm-name "${NAME_PREFIX}-aurora-replication-lag-high" \
  --state-value ALARM \
  --state-reason "DR pipeline test - $(date)"
```

**Expected:**
- Within ~30 seconds: email arrives at all subscribed addresses
- After 1-2 minutes: alarm auto-recovers to `OK` (real metric is healthy)
- A second "OK" email arrives

### 1.4 Trigger the composite alarm (P1 pager path)

```bash
# Force both children to ALARM
aws cloudwatch set-alarm-state --region $DR_REGION \
  --alarm-name "${NAME_PREFIX}-aurora-replication-lag-high" \
  --state-value ALARM --state-reason "composite-test"

aws cloudwatch set-alarm-state --region $DR_REGION \
  --alarm-name "${NAME_PREFIX}-efs-replication-lag-high" \
  --state-value ALARM --state-reason "composite-test"

# Verify composite state
sleep 15
aws cloudwatch describe-alarms --region $DR_REGION \
  --alarm-names "${NAME_PREFIX}-COMPOSITE-cross-region-replication-degraded" \
  --query 'CompositeAlarms[0].StateValue'
```

**Expected:** Composite flips to `ALARM`, a third email arrives from the
composite path, then everything auto-recovers.

### 1.5 Cross-region test (us-east-1 Route 53 alarm)

```bash
aws cloudwatch set-alarm-state --region us-east-1 \
  --alarm-name "${NAME_PREFIX}-route53-prod-app-unhealthy" \
  --state-value ALARM --state-reason "cross-region-test"
```

**Expected:** Email arrives from the us-east-1 SNS topic — validates that
cross-region SNS routing works.

### 1.6 Verify the dashboard renders

Open in browser:

```
https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#dashboards:name=prod-dr-failover-overview
```

**Expected:** 11 widgets render with real data. No "metric not found" or
red error icons. Alarm tiles green (assuming Level 1.3-1.5 alarms have
recovered). Line graphs show recent Aurora/EFS/ALB activity.

---

## Level 2 — Read-only Lambda tests (zero risk)

### 2.1 PreFlightChecks against real prod-dr

```bash
aws lambda invoke --region $DR_REGION \
  --function-name "${NAME_PREFIX}-preflight_checks" \
  --payload '{"mode":"managed","dry_run":true}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/preflight-out.json

cat /tmp/preflight-out.json | jq .
```

**Expected:** JSON report with `aurora_ready=true`, `efs_ready=true`,
`eks_ready=true`. **If any are false, FIX before running Level 4.** This
test catches configuration drift (wrong cluster IDs, missing replication,
nodegroup not reachable).

### 2.2 PostFailoverValidation probe

```bash
aws lambda invoke --region $DR_REGION \
  --function-name "${NAME_PREFIX}-post_failover_validation" \
  --payload '{"dry_run":true}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/postval-out.json

cat /tmp/postval-out.json | jq .
```

**Expected:** `{"status":"dry-run","note":"Skipping validation in dry-run"}`.
Confirms Lambda is invokable.

### 2.3 Approval handler rejects invalid signatures

Get the approval API URL:

```bash
aws apigatewayv2 get-apis --region $DR_REGION \
  --query "Items[?contains(Name,'approval')].[Name,ApiEndpoint]" \
  --output table
```

Test with bogus signature:

```bash
APPROVAL_URL="<paste-the-ApiEndpoint-from-above>/approve"
curl -i "${APPROVAL_URL}?action=approve&sig=WRONG&token=fake"
```

**Expected:** HTTP 403 with "Forbidden — Invalid signature" HTML response.

---

## Level 3 — ArgoCD alarm-suppression test (zero risk)

Run this any time you do a real ArgoCD deploy, or trigger one manually.

### 3.1 Verify the webhook URL is registered

```bash
aws apigatewayv2 get-apis --region $DR_REGION \
  --query "Items[?contains(Name,'argocd')].[Name,ApiEndpoint]" \
  --output table
```

### 3.2 Trigger a no-op sync and watch alarm suppression

In the prod EKS cluster:

```bash
kubectl config use-context arn:aws:eks:eu-west-1:495711089104:cluster/<your-prod-cluster>
argocd app sync accesshub-prod --force
```

In a separate terminal:

```bash
aws logs tail "/aws/lambda/${NAME_PREFIX}-alarm-actions-controller" \
  --region $DR_REGION --follow
```

**Expected log sequence:**
- `event=sync-started` → `DisableAlarmActions` invoked on 7 alarms
- (during deploy: alarms evaluate but don't email)
- `event=deployed` → `EnableAlarmActions` invoked on 7 alarms

Verify the disable actually happened mid-deploy:

```bash
aws cloudwatch describe-alarms --region $SRC_REGION \
  --alarm-names "${NAME_PREFIX}-alb-unhealthy-hosts" \
  --query 'MetricAlarms[0].ActionsEnabled'
```

- During sync: `False`
- After sync: `True`

### 3.3 Verify DynamoDB tracks the suppression

```bash
aws dynamodb scan --region $DR_REGION \
  --table-name "${NAME_PREFIX}-alarm-suppression-state" \
  --output table
```

### 3.4 Check Metric suppression status
```bash
export NAME_PREFIX="prod-dr-failover"

for r in eu-west-1 eu-central-1 us-east-1; do
  echo "===== $r metric alarms ====="
  aws cloudwatch describe-alarms \
    --region "$r" \
    --alarm-name-prefix "$NAME_PREFIX" \
    --query 'MetricAlarms[*].[AlarmName,ActionsEnabled,StateValue]' \
    --output table
done
```

During active sync: one item with `app=accesshub-prod`, `state=deploying`.
After sync: cleared (or TTL-expires within 45 min).

---

## Level 4 — Full state machine dry-run (the BIG validation)

> Only run this after Levels 1-3 pass. This exercises every layer of the DR
> pipeline end-to-end with zero production impact.

### 4.1 Start the dry-run

```bash
EXECUTION_ARN=$(aws stepfunctions start-execution \
  --region $DR_REGION \
  --state-machine-arn $STATE_MACHINE_ARN \
  --name "dr-dryrun-$(date +%Y%m%d-%H%M%S)" \
  --input '{"mode":"managed","dry_run":true,"target_node_desired":3,"target_replicas":3}' \
  --query 'executionArn' --output text)

echo "Started: $EXECUTION_ARN"
```

### 4.2 Watch execution progress

In a separate terminal:

```bash
while true; do
  status=$(aws stepfunctions describe-execution --region $DR_REGION \
    --execution-arn "$EXECUTION_ARN" --query 'status' --output text)
  echo "$(date +%H:%M:%S)  status=$status"
  [ "$status" != "RUNNING" ] && break
  sleep 5
done
```

### 4.3 Expected timeline

| t=    | Event | Where to see it |
|-------|-------|-----------------|
| 0s    | Execution starts | `status=RUNNING` |
| 5-30s | `PreFlightChecks` Lambda runs | Step Functions console execution history |
| ~30s  | State machine enters `ManualApprovalGate`, pauses | Status stays `RUNNING` |
| ~35s  | **Approval email arrives in inbox** | Email ✉️ |
| —     | **You click APPROVE link in email** | Browser shows green "Approved" page |
| +5s   | `AuroraFailover` Lambda runs (no-op in dry-run) | Execution history |
| +10s  | `EFSPromote`, `ScaleEKS` Lambdas run (no-ops) | Execution history |
| +12s  | `SkipWaitIfDryRun` Choice bypasses the 5-min ArgoCD wait | Execution history |
| +15s  | `PostFailoverValidation` Lambda runs (no-op) | Execution history |
| +20s  | `SuccessNotification` SNS publish | **Second email arrives** ✉️ |
| Total | ~50s after approval click → `status=SUCCEEDED` | |

### 4.4 Inspect the result

```bash
aws stepfunctions describe-execution --region $DR_REGION \
  --execution-arn "$EXECUTION_ARN" \
  --query '{status:status, startDate:startDate, stopDate:stopDate}'

aws stepfunctions describe-execution --region $DR_REGION \
  --execution-arn "$EXECUTION_ARN" \
  --query 'output' --output text | jq .
```

**Expected output JSON contains:**

```json
{
  "aurora":     { "Payload": { "status": "dry-run", "mode": "managed", "would_call": "rds.failover_global_cluster", ... } },
  "efs":        { "Payload": { "status": "dry-run", "would_call": "efs.delete_replication_configuration", ... } },
  "eks":        { "Payload": { "status": "dry-run", "would_scale_nodes_to": 3, "would_commit_replicas": 3 } },
  "validation": { "Payload": { "status": "dry-run", "note": "Skipping validation in dry-run" } }
}
```

### 4.5 Safety check — verify nothing actually changed

```bash
# Aurora — prod must still be the writer
aws rds describe-global-clusters --region $SRC_REGION \
  --global-cluster-identifier prod-accesshub-global \
  --query 'GlobalClusters[0].GlobalClusterMembers[*].[DBClusterArn,IsWriter]' \
  --output table

# EFS replication still active
aws efs describe-replication-configurations --region $SRC_REGION \
  --query 'Replications[*].[SourceFileSystemId,Destinations[0].Status]' \
  --output table

# DR EKS still warm-standby (desiredSize=0)
export DR_EKS_CLUSTER_NAME="prod-dr-accesshub-cluster"
aws eks list-nodegroups --region "$DR_REGION" --cluster-name "$DR_EKS_CLUSTER_NAME" --output table

export DR_NODEGROUP_NAME="core-ng"   # replace if output shows different name
aws eks describe-nodegroup --region "$DR_REGION" \
  --cluster-name "$DR_EKS_CLUSTER_NAME" \
  --nodegroup-name "$DR_NODEGROUP_NAME" \
  --query 'nodegroup.scalingConfig.{desired:desiredSize,max:maxSize,min:minSize}' \
  --output table


**All 4 must be unchanged.** Combined with both emails received and
execution `SUCCEEDED`, this proves the DR pipeline works end-to-end.

---

## Level 5 — Negative tests (verify failure paths)

### 5.1 Deny path

```bash
aws stepfunctions start-execution \
  --region $DR_REGION \
  --state-machine-arn $STATE_MACHINE_ARN \
  --name "dr-denytest-$(date +%Y%m%d-%H%M%S)" \
  --input '{"mode":"managed","dry_run":true}'
```

Wait for the approval email, then **click DENY**.

**Expected:** Execution ends in `FAILED` status with error `ApprovalDenied`.
A failure-notification email arrives.

### 5.2 Approval timeout (optional, slow)

Start a dry-run and don't click anything. After 1 hour (`approval_timeout_seconds=3600`),
execution fails with `States.Timeout`. Useful for confirming the timeout
wiring but not worth running unless suspected broken.

---

## Recommended monthly drill (~20 minutes active work)

1. Level 1.1, 1.2 — confirm everything exists (2 min)
2. Level 1.3 — single alarm test, confirm email pipeline (3 min)
3. Level 1.4 — composite alarm test (3 min)
4. Level 1.6 — dashboard render check (2 min)
5. Level 2.1 — preflight against real prod-dr (1 min — catches config drift)
6. Level 4 — full dry-run end-to-end (~3 minutes + approval click)
7. Level 4.5 — safety check (2 min)

Skip Level 3 unless you have a planned deploy.
Skip Level 5 unless quarterly negative-path validation is due.

---

## Success criteria

By the end of testing, you should have:

- 7+ emails in the inbox from the various test alarms and dry-run execution
- A green dashboard with real data
- A `SUCCEEDED` Step Functions execution that ran every state
- Confirmation prod Aurora, EFS, DNS, EKS were all untouched

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| No emails arrive | SNS subscription stuck in `PendingConfirmation` | Check inbox spam; click confirmation link from AWS |
| Lambda invoke fails with `AccessDenied` | IAM permission gap | `aws logs tail /aws/lambda/<name>` will show the exact missing action |
| Preflight reports `aurora_ready=false` | Cluster name in tfvars doesn't match reality | Check `global_cluster_id` and `dr_cluster_arn` in tfvars |
| Preflight reports `efs_ready=false` | EFS replication broken or wrong ID | Verify replication active in eu-west-1 EFS console; check `source_efs_id`, `dr_efs_id` |
| Preflight reports `eks_ready=false` | DR nodegroup name wrong | Check `dr_eks_nodegroup_name` matches actual nodegroup |
| Approval link returns 403 | `approval_shared_secret_arn` value mismatch | Check Secrets Manager value vs what Lambda env was built with |
| Dashboard widgets say "metric not found" | Resource name mismatch in tfvars | Check `prod_alb_name`, `prod_cluster_identifier`, `dr_cluster_identifier`, `dr_efs_id` |
| Composite alarm never fires | Child alarms in different regions | Verify both children are in eu-central-1 |
| ArgoCD webhook returns 401 | HMAC secret mismatch | Re-sync the secret between Secrets Manager and `argocd-notifications-cm` ConfigMap |
| Dry-run "skip wait" still waits 5 minutes | Old state machine definition cached | Re-deploy: `terraform apply` will update `aws_sfn_state_machine.dr_failover` definition |

---

## Resource name reference

(Derive from `name_prefix = "prod-dr-failover"`.)

| Resource type | Name |
|---------------|------|
| State machine | `prod-dr-failover-state-machine` |
| Lambdas | `prod-dr-failover-preflight_checks`, `-aurora_failover`, `-efs_promote`, `-eks_scale`, `-post_failover_validation`, `-approval_handler`, `-alarm_actions_controller` |
| Single alarms | `prod-dr-failover-<aurora-replication-lag-high \| efs-replication-lag-high \| alb-unhealthy-hosts \| alb-target-5xx-high \| aurora-no-connections \| aurora-db-load-high \| route53-prod-app-unhealthy>` |
| Composite alarm | `prod-dr-failover-COMPOSITE-cross-region-replication-degraded` |
| Dashboard | `prod-dr-failover-overview` |
| DynamoDB | `prod-dr-failover-alarm-suppression-state` |
| SNS topics | `prod-dr-failover-dr-alerts` (eu-central-1, eu-west-1, us-east-1), `prod-dr-failover-dr-approval`, `prod-dr-failover-dr-complete` |
