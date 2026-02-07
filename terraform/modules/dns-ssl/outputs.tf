output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "hosted_zone_name_servers" {
  description = "Name servers for the hosted zone — set these in Namecheap"
  value       = aws_route53_zone.main.name_servers
}

output "acm_cert_arn" {
  description = "ARN of the validated wildcard ACM certificate"
  value       = aws_acm_certificate_validation.wildcard.certificate_arn
}

