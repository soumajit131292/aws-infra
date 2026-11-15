region            = "eu-west-1"
repository_prefix = "accesshub-qa"

# Same services as the build workflows (build-from-app-repo.yml matrix +
# build-health-aggregator.yml). dbmigration's repository is "db-migration".
services = [
  "adminsvc",
  "apponbsvc",
  "pgmodsvc",
  "loginmodsvc",
  "snowmodsvc",
  "gatewaysvc",
  "ahschedular",
  "scimpersist",
  "grcsoapws",
  "ahservicesvc",
  "antdui",
  "db-migration",
  "health-aggregator",
]

keep_last_images = 30
force_delete     = true

tags = {
  Environment = "qa"
  Project     = "crave"
  ManagedBy   = "terraform"
  Component   = "ecr"
}
