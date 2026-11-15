aws_region = "eu-west-1"

github_org  = "CraveGit"
github_repo = "CRAVE_INT_ACCESSHUB_cicd"

# build-from-app-repo.yml is started by repository_dispatch, which always runs
# on the deployment repo's default branch (main), so the OIDC token says
# ref:refs/heads/main for QA builds too. What keeps QA and prod apart is the
# separate role (AWS_ROLE_TO_ASSUME_QA), which the workflow only uses for
# source_branch = customer/ah_booking_qa.
allowed_branches = [
  "main"
]

role_name = "github-actions-crave-repo-qa"
