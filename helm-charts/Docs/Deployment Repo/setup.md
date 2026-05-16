# Deployment Repo Setup (CraveGit/CRAVE_INT_ACCESSHUB_cicd)

This app repo now sends a `repository_dispatch` event to:

- `CraveGit/CRAVE_INT_ACCESSHUB_cicd`

when `main` is updated.

## 1. Required secret in app repo (this repo)

Create secret:

- `DEPLOY_REPO_DISPATCH_TOKEN`

Use a PAT/GitHub token with permission to trigger workflows/dispatch in `CraveGit/CRAVE_INT_ACCESSHUB_cicd`.

## 2. Add this workflow in deployment repo

Create file in deployment repo:

- `.github/workflows/build-from-app-repo.yml`

Use the template from `docs/deployment-repo/workflow-build-from-app-repo.yml` in this repo.

## 3. Required secrets in deployment repo

- `SOURCE_REPO_READ_TOKEN` (read access to `CraveGit/CRAVE_INT_ACCESSHUB_cicd_cbt_template`)
- `AWS_ROLE_TO_ASSUME`
- `AWS_REGION`

## 4. Required files in deployment repo

Move/copy deployment assets from app repo to deployment repo:

- Dockerfiles
- docker scripts
- Helm chart
- Argo CD manifests

Then keep those files changing only in deployment repo.
