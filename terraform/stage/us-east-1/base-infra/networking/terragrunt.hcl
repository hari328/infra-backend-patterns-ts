include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/networking"
}

inputs = {
  project              = "hari328"
  environment          = "stage"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
}

