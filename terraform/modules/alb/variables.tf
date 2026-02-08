variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "acm_cert_arn" {
  description = "ARN of the ACM certificate for HTTPS listener"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group egress"
  type        = string
  default     = "10.0.0.0/16"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for creating DNS records"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (e.g. hari328.net)"
  type        = string
}

