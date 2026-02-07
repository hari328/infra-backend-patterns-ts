# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name        = var.domain_name
    Project     = var.project
    Environment = var.environment
  }
}

# ACM Wildcard Certificate
# Note: ACM rejects '*' in tag values, so we use 'wildcard' in the Name tag
resource "aws_acm_certificate" "wildcard" {
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"

  tags = {
    Name = "wildcard.${var.domain_name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records — one per domain in the cert
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]

  allow_overwrite = true
}

# Wait for certificate validation to complete
resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Write outputs to SSM for other modules to consume
resource "aws_ssm_parameter" "hosted_zone_id" {
  name  = "/infra/hosted-zone-id"
  type  = "String"
  value = aws_route53_zone.main.zone_id
}

resource "aws_ssm_parameter" "acm_cert_arn" {
  name  = "/infra/acm-cert-arn"
  type  = "String"
  value = aws_acm_certificate_validation.wildcard.certificate_arn
}

