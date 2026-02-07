locals {
  env_vars    = yamldecode(file("${find_in_parent_folders("env.yaml")}"))
  aws_region  = local.env_vars["aws_region"]
  environment = local.env_vars["environment"]
  project     = local.env_vars["project"]
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  default_tags {
    tags = {
      project     = "${local.project}"
      environment = "${local.environment}"
      managed_by  = "terragrunt"
      repo        = "hari328/infra-backend-patterns-ts"
    }
  }
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "hari328-infra-${local.environment}-tfstate"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "hari328-infra-${local.environment}-tflock"
  }
}

