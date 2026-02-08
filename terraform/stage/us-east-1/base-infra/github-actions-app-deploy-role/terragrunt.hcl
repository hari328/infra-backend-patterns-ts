include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/github-actions-app-deploy-role"
}

inputs = {
  role_name           = "github-actions-app-deploy"
  github_repositories = ["repo:hari328/backend-patterns-ts:*"]
}

