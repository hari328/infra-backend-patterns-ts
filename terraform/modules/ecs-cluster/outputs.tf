output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.name
}

output "autoscaling_group_arn" {
  description = "ARN of the EC2 Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_arn
}

output "autoscaling_group_name" {
  description = "Name of the EC2 Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_name
}

