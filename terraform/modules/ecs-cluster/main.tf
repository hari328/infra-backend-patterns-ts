# ECS-optimized AMI (Amazon Linux 2023)
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended"
}

################################################################################
# ECS Cluster
################################################################################

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 5.0"

  cluster_name = "${var.project}-${var.environment}"

  # Use EC2 capacity provider, not Fargate
  default_capacity_provider_use_fargate = false

  autoscaling_capacity_providers = {
    ec2-ondemand = {
      auto_scaling_group_arn         = module.autoscaling.autoscaling_group_arn
      managed_draining               = "ENABLED"
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 2
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 80
      }
    }
  }
}

################################################################################
# EC2 Auto Scaling Group
################################################################################

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 9.0"

  name = "${var.project}-${var.environment}-ecs"

  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = var.instance_type

  security_groups                 = [module.autoscaling_sg.security_group_id]
  user_data                       = base64encode(local.user_data)
  ignore_desired_capacity_changes = true

  # IAM instance profile for ECS agent + SSM access
  create_iam_instance_profile = true
  iam_role_name               = "${var.project}-${var.environment}-ecs"
  iam_role_description        = "ECS container instance role for ${var.project}-${var.environment}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = var.private_subnet_ids
  health_check_type   = "EC2"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  # IMDSv2 enforced (AWS security best practice)
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # Required for managed_termination_protection = "ENABLED"
  protect_from_scale_in = true

  # Required tag for ECS managed scaling
  autoscaling_group_tags = {
    AmazonECSManaged = true
  }
}

################################################################################
# EC2 Security Group — inbound all from ALB SG, outbound all
################################################################################

module "autoscaling_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project}-${var.environment}-ecs"
  description = "ECS container instances - allows traffic from ALB"
  vpc_id      = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = var.alb_security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]
}

################################################################################
# Locals
################################################################################

locals {
  user_data = <<-EOT
    #!/bin/bash
    cat <<'EOF' >> /etc/ecs/ecs.config
    ECS_CLUSTER=${var.project}-${var.environment}
    ECS_ENABLE_TASK_IAM_ROLE=true
    EOF
  EOT
}

################################################################################
# SSM Parameters for Layer 2 consumption
################################################################################

resource "aws_ssm_parameter" "cluster_arn" {
  name  = "/infra/cluster-arn"
  type  = "String"
  value = module.ecs_cluster.arn
}

resource "aws_ssm_parameter" "cluster_name" {
  name  = "/infra/cluster-name"
  type  = "String"
  value = module.ecs_cluster.name
}

