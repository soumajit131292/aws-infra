# AccessHub Image Verification Guide (Pre-Filled)

This is the pre-filled version for:

- GitHub repo: `CraveGit/CRAVE_INT_ACCESSHUB_cicd_cbt_template`
- AWS account: `495711089104`
- AWS region: `us-east-1`
- ECR registry: `495711089104.dkr.ecr.us-east-1.amazonaws.com`

## 1. Prerequisites

Install:
- `cosign` (v2+)
- `jq`
- `aws` CLI (if ECR requires auth)

Login to ECR:

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 495711089104.dkr.ecr.us-east-1.amazonaws.com
```

## 2. Set image reference by digest

Example for `adminsvc`:

```bash
export IMAGE="495711089104.dkr.ecr.us-east-1.amazonaws.com/accesshub/adminsvc"
export DIGEST="sha256:<digest>"
export IMAGE_REF="${IMAGE}@${DIGEST}"
```

Use digest from release metadata (for example from `deploy/helm/accesshub/values-prod.yaml`).

## 3. Verify cosign signature (keyless)

### For backend images (from `docker-images-ci.yml`)

```bash
cosign verify \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  --certificate-identity-regexp "https://github.com/CraveGit/CRAVE_INT_ACCESSHUB_cicd/.*"
 \
  "${IMAGE_REF}"
```

### For frontend image (from `docker-antdui-ci.yml`)

```bash
cosign verify \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  --certificate-identity-regexp "https://github.com/CraveGit/CRAVE_INT_ACCESSHUB_cicd/.*"
  \
  "${IMAGE_REF}"
```

## 4. Verify provenance attestation (SLSA)

```bash
cosign verify-attestation \
  --type slsaprovenance \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  --certificate-identity-regexp "https://github.com/CraveGit/CRAVE_INT_ACCESSHUB_cicd/.*" \
  "${IMAGE_REF}"
```

Decode payload:

```bash
cosign verify-attestation \
  --type slsaprovenance \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  --certificate-identity-regexp "https://github.com/CraveGit/CRAVE_INT_ACCESSHUB_cicd/.*" \
  "${IMAGE_REF}" | jq -r '.[0].payload' | base64 -d | jq
```

## 5. Verify SBOM attestation (SPDX)

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  --certificate-identity-regexp "https://github.com/CraveGit/CRAVE_INT_ACCESSHUB_cicd/.*" \
  "${IMAGE_REF}"
```

Decode payload:

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  --certificate-identity-regexp "https://github.com/CraveGit/CRAVE_INT_ACCESSHUB_cicd/.*" \
  "${IMAGE_REF}" | jq -r '.[0].payload' | base64 -d | jq
```

## 6. ECR repo examples

- `accesshub/adminsvc`
- `accesshub/ahschedular`
- `accesshub/apponbsvc`
- `accesshub/gatewaysvc`
- `accesshub/grcsoapws`
- `accesshub/loginmodsvc`
- `accesshub/pgmodsvc`
- `accesshub/scimpersist`
- `accesshub/snowmodsvc`
- `accesshub/antdui`

## 7. Acceptance checklist

Accept image only if all pass:

1. `cosign verify` succeeds with issuer `https://token.actions.githubusercontent.com` and expected workflow identity.
2. `verify-attestation --type slsaprovenance` succeeds and commit/workflow metadata matches release.
3. `verify-attestation --type spdxjson` succeeds and SBOM exists.
4. Digest exactly matches the release digest you were given.


cosign verify \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  --certificate-identity-regexp "https://github.com/CraveGit/CRAVE_INT_ACCESSHUB_cicd/.*"
 \
  "495711089104.dkr.ecr.us-east-1.amazonaws.com/accesshub/adminsvc:sha256-2b72fc1758acf8dab2e659b42d4ca4c938ba9d90ce540fc1683b34c27181ad31.sig"

-------------------------------------------------------

  EXample Cosign Verification : 

  cosign verify   --certificate-oidc-issuer https://token.actions.githubusercontent.com   --certificate-identity-regexp https://github.com/CraveGit/CRAVE_INT_ACCESSHUB_cicd/.*   495711089104.dkr.ecr.us-east-1.amazonaws.com/accesshub/adminsvc@sha256:4afbaca7290d2b12efa4c7420d15b67480fddb7afff5680615db4c693c805827
