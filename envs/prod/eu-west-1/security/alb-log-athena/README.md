# Prod ALB Access Logs in Athena

This stack makes the existing `accesshub-prod-alb` access logs queryable in Athena.

## What It Creates

- Glue database: `prod_accesshub_logs`
- Glue external table: `alb_access_logs`
- Athena workgroup: `prod-accesshub-alb-logs`
- Athena result location in the central security log bucket
- Saved Athena queries for recent errors, slow requests, and top client IPs
- Optional IAM managed policy for read/query access

The table reads logs from the ALB access log bucket created by the prod ALB controller stack.

## Cost Guard

The Athena workgroup enforces a 10 GiB per-query scan limit by default:

```text
10737418240 bytes ~= 10 GiB ~= about $0.05 maximum per query
```

## Example Queries

Recent errors:

```sql
SELECT
  time,
  client_ip,
  request_verb,
  request_url,
  elb_status_code,
  target_status_code,
  target_processing_time,
  trace_id
FROM prod_accesshub_logs.alb_access_logs
WHERE day BETWEEN date_format(current_date - interval '1' day, '%Y/%m/%d')
  AND date_format(current_date, '%Y/%m/%d')
  AND (elb_status_code >= 400 OR try_cast(target_status_code AS integer) >= 400)
ORDER BY time DESC
LIMIT 100;
```

Slow target responses:

```sql
SELECT
  time,
  client_ip,
  request_verb,
  request_url,
  elb_status_code,
  target_status_code,
  target_processing_time,
  trace_id
FROM prod_accesshub_logs.alb_access_logs
WHERE day = date_format(current_date, '%Y/%m/%d')
  AND target_processing_time >= 1
ORDER BY target_processing_time DESC
LIMIT 100;
```

Top URLs with errors today:

```sql
SELECT
  request_url,
  count(*) AS request_count,
  count_if(elb_status_code >= 400 OR try_cast(target_status_code AS integer) >= 400) AS error_count
FROM prod_accesshub_logs.alb_access_logs
WHERE day = date_format(current_date, '%Y/%m/%d')
GROUP BY request_url
ORDER BY error_count DESC, request_count DESC
LIMIT 50;
```
