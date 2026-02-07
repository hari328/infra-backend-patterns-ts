module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name    = "${var.project}-${var.environment}"
  vpc_id  = var.vpc_id
  subnets = var.public_subnet_ids

  # Internet-facing ALB
  internal = false

  # Allow Terraform to destroy (stage-friendly, override in prod)
  enable_deletion_protection = false

  # Security Group — managed by the community module
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr
    }
  }

  listeners = {
    http-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.acm_cert_arn
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

      # Default action: 404 — Layer 2 adds listener rules per service
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  }
}

# Write outputs to SSM for Layer 2 consumption
resource "aws_ssm_parameter" "alb_arn" {
  name  = "/infra/alb-arn"
  type  = "String"
  value = module.alb.arn
}

resource "aws_ssm_parameter" "alb_dns_name" {
  name  = "/infra/alb-dns-name"
  type  = "String"
  value = module.alb.dns_name
}

resource "aws_ssm_parameter" "alb_security_group_id" {
  name  = "/infra/alb-security-group-id"
  type  = "String"
  value = module.alb.security_group_id
}

resource "aws_ssm_parameter" "alb_listener_arn" {
  name  = "/infra/alb-listener-arn"
  type  = "String"
  value = module.alb.listeners["https"].arn
}

