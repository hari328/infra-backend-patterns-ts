include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/dns-ssl"
}

# Provider alias without default_tags for ACM
# ACM rejects certain characters in tag values
generate "acm_provider" {
  path      = "acm-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  alias  = "acm"
  region = "us-east-1"
  default_tags {
    tags = {}
  }
}
EOF
}

inputs = {
  project     = "hari328"
  environment = "stage"
  domain_name = "hari328.net"
}

