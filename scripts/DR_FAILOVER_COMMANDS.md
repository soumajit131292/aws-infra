# DR Failover Handy Commands

Use from repo root: `/Users/soumajitroy/Documents/crave`

## 1) Setup

```bash
cd /Users/soumajitroy/Documents/crave
chmod +x ./scripts/dr-failover-sm.sh
```

## 2) State Machine Commands

```bash
# Describe state machine
./scripts/dr-failover-sm.sh describe

# Start SAFE dry-run execution
./scripts/dr-failover-sm.sh dry-run

# Start REAL failover execution (destructive)
./scripts/dr-failover-sm.sh real-run

# Check execution status
./scripts/dr-failover-sm.sh status <execution-arn>

# Check recent execution history
./scripts/dr-failover-sm.sh history <execution-arn>
```

## 3) Optional Environment Overrides

```bash
DR_REGION=eu-central-1 \
ACCOUNT_ID=495711089104 \
NAME_PREFIX=prod-dr-failover \
TARGET_NODE_DESIRED=3 \
TARGET_REPLICAS=3 \
./scripts/dr-failover-sm.sh dry-run
```

## 4) Alarm Suppression Verification

```bash
export DR_REGION="eu-central-1"
export SRC_REGION="eu-west-1"
export NAME_PREFIX="prod-dr-failover"
```

```bash
# Lambda logs for suppress/resume flow
aws logs tail "/aws/lambda/${NAME_PREFIX}-alarm-actions-controller" \
  --region "$DR_REGION" --follow
```

```bash
# DynamoDB suppression state row
aws dynamodb scan \
  --region "$DR_REGION" \
  --table-name "${NAME_PREFIX}-alarm-suppression-state" \
  --output table
```

```bash
# Alarm action flags in all regions
for r in eu-west-1 eu-central-1 us-east-1; do
  echo "===== $r metric alarms ====="
  aws cloudwatch describe-alarms \
    --region "$r" \
    --alarm-name-prefix "$NAME_PREFIX" \
    --query 'MetricAlarms[*].[AlarmName,ActionsEnabled,StateValue]' \
    --output table
done
```

## 5) EKS Scale Lambda Dry-Run (Safe)

```bash
aws lambda invoke --region "$DR_REGION" \
  --function-name "${NAME_PREFIX}-eks_scale" \
  --payload '{"dry_run":true}' \
  --cli-binary-format raw-in-base64-out /tmp/eks-scale-dryrun.json

cat /tmp/eks-scale-dryrun.json | jq .
```
