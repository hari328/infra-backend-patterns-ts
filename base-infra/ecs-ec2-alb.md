# ECS Cluster + EC2 ASG + ALB

These three work together to run and expose your containers.

## How they connect

```
Internet → ALB → Target Group → ECS Tasks (running on EC2 instances managed by ASG)
```

---

## 1. ECS Cluster

Just a **logical name** — a namespace that groups your services. No compute, no cost.

```
aws_ecs_cluster "main" {
  name = "my-cluster"
}
```

### Capacity Provider
Links the cluster to your EC2 ASG. Tells ECS: "when you need to place a task, use these EC2 instances."

Also handles **managed scaling** — if ECS needs to run a task but no EC2 instance has room, it tells the ASG to launch more instances.

---

## 2. EC2 ASG (Auto Scaling Group)

The fleet of EC2 instances that actually run your containers.

### Components:

**Launch Template** — the blueprint for each EC2 instance:
- AMI: `amazon-linux-2-ecs-optimized` (has ECS agent pre-installed)
- Instance type: `t3.medium` (2 vCPU, 4GB — good starting point)
- IAM instance profile: lets the instance register with ECS
- User data script: tells the ECS agent which cluster to join
- Security group: what traffic the instance accepts

**ASG** — manages the fleet:
- min: 1, max: 3, desired: 1 (start small)
- Spreads instances across your 2 private subnets (multi-AZ)
- Scales out when ECS capacity provider says "I need more room"
- Scales in when instances are underutilized

### The user data script (critical piece):
```bash
#!/bin/bash
echo "ECS_CLUSTER=my-cluster" >> /etc/ecs/ecs.config
```
This one line is how an EC2 instance knows which ECS cluster to join.

---

## 3. ALB (Application Load Balancer)

Single entry point for all HTTP traffic. Routes requests to the right service.

### Components:

**ALB itself** — sits in public subnets, internet-facing.

**Listeners:**
- Port 80 (HTTP) → redirects to 443
- Port 443 (HTTPS) → uses ACM cert, forwards to target groups

**Target Groups** — one per service (created in Layer 2, not here):
- backend-patterns-ts → target group on port 3000
- Grafana → target group on port 3000
- Each has its own health check path

**Listener Rules** — route by hostname or path (also Layer 2):
- `api.yourdomain.com` → backend-patterns-ts target group
- `grafana.yourdomain.com` → Grafana target group

### What Layer 1 creates:
- The ALB itself
- The HTTPS listener (with default action: return 404)
- The HTTP listener (redirect to HTTPS)
- Security group allowing inbound 80/443 from the internet

### What Layer 2 creates (per service):
- Target group
- Listener rule (hostname/path routing)

---

## How a request flows

```
1. User hits api.yourdomain.com
2. DNS (Route53) resolves to ALB's IP
3. ALB receives request on port 443
4. Listener rule matches hostname → forwards to backend-patterns-ts target group
5. Target group picks a healthy ECS task
6. Request reaches your container on port 3000
```

---

## Terraform resources (Layer 1)

| Resource | Count | Purpose |
|---|---|---|
| `aws_ecs_cluster` | 1 | Logical grouping |
| `aws_ecs_capacity_provider` | 1 | Links cluster to ASG |
| `aws_launch_template` | 1 | EC2 instance blueprint |
| `aws_autoscaling_group` | 1 | Manages EC2 fleet |
| `aws_iam_instance_profile` | 1 | EC2 → ECS permissions |
| `aws_iam_role` | 1 | Role for the instance profile |
| `aws_lb` | 1 | The ALB |
| `aws_lb_listener` | 2 | HTTP (redirect) + HTTPS |
| `aws_security_group` | 2 | One for ALB, one for EC2 instances |

## Security group rules

**ALB security group:**
- Inbound: 80, 443 from `0.0.0.0/0` (internet)
- Outbound: all to VPC CIDR

**EC2 instance security group:**
- Inbound: all traffic from ALB security group only
- Outbound: all (needs to reach NAT for image pulls, etc.)

## Cost
- ECS cluster — **free**
- t3.medium On-Demand — ~$30/month
- ALB — ~$16/month + data transfer
- Total: ~$46/month for the compute + load balancer layer

