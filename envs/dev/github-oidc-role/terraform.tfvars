aws_region = "us-east-1"

github_org  = "CraveGit"
github_repo = "CRAVE_INT_ACCESSHUB_cicd"
# "CRAVE_INT_ACCESSHUB_cicd_cbt_template"

allowed_branches = [
  "main",
  "release/*"
]

role_name = "github-actions-crave-microservice"
