# CRAVE_INT_ACCESSHUB Deployment Repo Template

This folder is a bootstrap template for deployment repo:

- `CraveGit/CRAVE_INT_ACCESSHUB_cicd`

## Included

- `.github/workflows/build-from-app-repo.yml`
- `docker/services/*` (backend service Dockerfiles)
- `docker/scripts/*` (runtime startup scripts)
- `docker/frontend/dockerfile` (frontend build Dockerfile)
- `helm/accesshub/*` (Helm chart)
- `argocd/accesshub-application.yaml` (Argo CD app)

## How build flow works

1. App repo dispatches event to deployment repo.
2. Deployment workflow checks out app repo source at exact SHA.
3. Dockerfiles from this deployment repo are used to build images.
4. Images are signed (cosign), SBOM and provenance generated.
5. Helm `values.yaml` digests are updated in deployment repo.

## Required deployment repo secrets

- `SOURCE_REPO_READ_TOKEN`
- `AWS_ROLE_TO_ASSUME`
- `AWS_REGION`

## Required app repo secret

- `DEPLOY_REPO_DISPATCH_TOKEN`

## Important paths expected by workflow

- Backend Dockerfiles: `docker/services/`
- Runtime scripts: `docker/scripts/`
- Frontend Dockerfile: `docker/frontend/dockerfile`
- Helm values digest file: `helm/accesshub/values-prod.yaml`
