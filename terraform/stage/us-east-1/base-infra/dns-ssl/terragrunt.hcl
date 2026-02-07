include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/dns-ssl"
}

inputs = {
  project     = "hari328"
  environment = "stage"
  domain_name = "hari328.net"
}

