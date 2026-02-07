include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/ecs-cluster"
}

dependency "networking" {
  config_path = "../networking"
}

dependency "alb" {
  config_path = "../alb"
}

inputs = {
  project               = "hari328"
  environment           = "stage"
  vpc_id                = dependency.networking.outputs.vpc_id
  private_subnet_ids    = dependency.networking.outputs.private_subnets
  alb_security_group_id = dependency.alb.outputs.alb_security_group_id
}

