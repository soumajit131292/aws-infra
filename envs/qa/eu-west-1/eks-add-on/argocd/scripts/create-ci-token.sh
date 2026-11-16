#!/usr/bin/env bash
# Creates the QA Argo CD "ci" API account (used by run-tenant-bootstrap.yml),
# grants it get/update/sync on applications, generates a token, verifies it,
# and prints the two GitHub secret values:
#   ARGOCD_SERVER_QA, ARGOCD_AUTH_TOKEN_QA
#
# Run on the QA jumphost with kubectl pointed at the QA cluster:
#   ./create-ci-token.sh            # token valid 90 days
#   EXPIRES_IN=30d ./create-ci-token.sh
set -euo pipefail

ACCOUNT="ci"
EXPIRES_IN="${EXPIRES_IN:-90d}"
NS="argocd"

step() { printf '\n==> %s\n' "$*"; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

command -v kubectl >/dev/null || die "kubectl not found"
command -v argocd  >/dev/null || die "argocd CLI not found (install it first, step 2)"

# --- Safety: QA cluster only -------------------------------------------------
step "Checking kubectl context"
ctx_cluster="$(kubectl config view --minify -o jsonpath='{.contexts[0].context.cluster}')"
case "$ctx_cluster" in
  *qa-accesshub-cluster) echo "OK: $ctx_cluster" ;;
  *) die "kubectl context is '$ctx_cluster', not the QA cluster. Run:
  aws eks update-kubeconfig --region eu-west-1 --name qa-accesshub-cluster" ;;
esac

# --- Argo CD address ---------------------------------------------------------
step "Resolving Argo CD address"
ARGOCD_HOST="$(kubectl -n "$NS" get ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')"
[ -n "$ARGOCD_HOST" ] || die "Argo CD ingress has no address yet (is the ALB up?)"
echo "OK: $ARGOCD_HOST"
OPTS=(--server "$ARGOCD_HOST" --grpc-web --plaintext)

# --- Step 4: admin login -----------------------------------------------------
step "Step 4: logging in as admin"
ADMIN_PW="${ARGOCD_ADMIN_PASSWORD:-}"
if [ -z "$ADMIN_PW" ]; then
  ADMIN_PW="$(kubectl -n "$NS" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)"
fi
if [ -z "$ADMIN_PW" ]; then
  read -r -s -p "argocd-initial-admin-secret not found. Enter the admin password: " ADMIN_PW
  echo
fi
argocd login "$ARGOCD_HOST" --username admin --password "$ADMIN_PW" --grpc-web --plaintext >/dev/null
unset ADMIN_PW
echo "OK: logged in"

# --- Step 5: API-only account ------------------------------------------------
step "Step 5: enabling account '$ACCOUNT' (apiKey only, no UI login)"
kubectl -n "$NS" patch configmap argocd-cm --type merge \
  -p "{\"data\":{\"accounts.${ACCOUNT}\":\"apiKey\"}}" >/dev/null
echo "OK"

# --- Step 6: RBAC (merge, never overwrite existing policy lines) ------------
step "Step 6: granting $ACCOUNT get/update/sync on applications"
WANT="p, role:ci, applications, get, default/*, allow
p, role:ci, applications, update, default/*, allow
p, role:ci, applications, sync, default/*, allow
g, ${ACCOUNT}, role:ci"

CURRENT="$(kubectl -n "$NS" get configmap argocd-rbac-cm -o jsonpath='{.data.policy\.csv}' 2>/dev/null || true)"
NEW="$CURRENT"
while IFS= read -r line; do
  [ -n "$line" ] || continue
  if ! printf '%s\n' "$CURRENT" | grep -qxF "$line"; then
    NEW="${NEW:+$NEW
}$line"
  fi
done <<< "$WANT"

if [ "$NEW" = "$CURRENT" ]; then
  echo "OK: policy already present, nothing to change"
else
  [ -n "$CURRENT" ] && echo "Existing policy.csv kept; appending missing lines."
  kubectl -n "$NS" create configmap argocd-rbac-cm --from-literal="policy.csv=$NEW" \
    --dry-run=client -o yaml | kubectl -n "$NS" apply -f - >/dev/null
  echo "OK: policy.csv now:"
  printf '%s\n' "$NEW" | sed 's/^/    /'
fi

# --- Step 7: restart server so the account/RBAC are loaded -------------------
step "Step 7: restarting argocd-server"
kubectl -n "$NS" rollout restart deploy argocd-server >/dev/null
kubectl -n "$NS" rollout status deploy argocd-server --timeout=300s

# --- Step 8: re-login and generate token -------------------------------------
step "Step 8: generating token for '$ACCOUNT' (expires in $EXPIRES_IN)"
ADMIN_PW="${ARGOCD_ADMIN_PASSWORD:-}"
if [ -z "$ADMIN_PW" ]; then
  ADMIN_PW="$(kubectl -n "$NS" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)"
fi
if [ -z "$ADMIN_PW" ]; then
  read -r -s -p "Enter the admin password again: " ADMIN_PW
  echo
fi
for _ in 1 2 3 4 5 6; do
  if argocd login "$ARGOCD_HOST" --username admin --password "$ADMIN_PW" --grpc-web --plaintext >/dev/null 2>&1; then
    break
  fi
  sleep 10
done
unset ADMIN_PW

argocd account list "${OPTS[@]}" | grep -E "^${ACCOUNT}[[:space:]]" >/dev/null \
  || die "account '$ACCOUNT' not visible after restart; check argocd-cm"

TOKEN="$(argocd account generate-token --account "$ACCOUNT" --expires-in "$EXPIRES_IN" "${OPTS[@]}")"
[ -n "$TOKEN" ] || die "empty token"
echo "OK: token generated"

# --- Step 9: verify the token as the workflow will use it --------------------
step "Step 9: verifying token"
APPS="$(argocd app list --server "$ARGOCD_HOST" --auth-token "$TOKEN" --grpc-web --plaintext -o name 2>&1)" \
  || die "token rejected: $APPS"
echo "Applications visible to '$ACCOUNT':"
printf '%s\n' "$APPS" | sed 's/^/    /'
if ! printf '%s\n' "$APPS" | grep -q "accesshub-qa-tenant-bootstrap"; then
  echo
  echo "NOTE: accesshub-qa-tenant-bootstrap is not listed yet. Apply it before running the workflow:"
  echo "  kubectl apply -f helm-charts/argocd/accesshub-tenant-bootstrap-application-qa.yaml"
fi

# --- Output for GitHub -------------------------------------------------------
cat <<EOF

================================================================
 GitHub secrets for CraveGit/CRAVE_INT_ACCESSHUB_cicd
 (Settings > Secrets and variables > Actions)
================================================================
ARGOCD_SERVER_QA:
$ARGOCD_HOST

ARGOCD_AUTH_TOKEN_QA:
$TOKEN
================================================================
Paste both, then clear this terminal (clear; history -c).
The token expires in $EXPIRES_IN; re-run this script to rotate it.
EOF
