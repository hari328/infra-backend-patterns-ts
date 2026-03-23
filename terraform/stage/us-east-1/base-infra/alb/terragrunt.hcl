include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/alb"
}

dependency "networking" {
  config_path = "../networking"
}

dependency "dns_ssl" {
  config_path = "../dns-ssl"
}

inputs = {
  project           = "hari328"
  environment       = "stage"
  vpc_id            = dependency.networking.outputs.vpc_id
  public_subnet_ids = dependency.networking.outputs.public_subnets
  vpc_cidr          = dependency.networking.outputs.vpc_cidr_block
  acm_cert_arn      = dependency.dns_ssl.outputs.acm_cert_arn
  hosted_zone_id    = dependency.dns_ssl.outputs.hosted_zone_id
  domain_name       = "hari328.net"
}

