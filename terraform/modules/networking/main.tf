module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = "${var.project}-${var.environment}"
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  # Single NAT Gateway — saves ~$32/month vs one per AZ
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # DNS support required for ECS service discovery
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    Type = "public"
  }

  private_subnet_tags = {
    Type = "private"
  }
}

# Write outputs to SSM so Layer 2 can read them without hard-coded IDs
resource "aws_ssm_parameter" "vpc_id" {
  name  = "/infra/vpc-id"
  type  = "String"
  value = module.vpc.vpc_id
}

resource "aws_ssm_parameter" "public_subnet_ids" {
  name  = "/infra/public-subnet-ids"
  type  = "StringList"
  value = join(",", module.vpc.public_subnets)
}

resource "aws_ssm_parameter" "private_subnet_ids" {
  name  = "/infra/private-subnet-ids"
  type  = "StringList"
  value = join(",", module.vpc.private_subnets)
}

