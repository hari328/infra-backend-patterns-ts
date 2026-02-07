output "alb_arn" {
  description = "ARN of the ALB"
  value       = module.alb.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = module.alb.security_group_id
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = module.alb.listeners["https"].arn
}

output "alb_zone_id" {
  description = "Route53 zone ID of the ALB (for alias records)"
  value       = module.alb.zone_id
}

