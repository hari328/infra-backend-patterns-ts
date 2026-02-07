# High-Level Architecture

## Deployment Layers

| Layer | What | How often it changes | Where Terraform lives |
|---|---|---|---|
| **Layer 1** | Shared platform infra | Rarely | `terraform/base-infra/` (this repo) |
| **Layer 2a** | Application (backend-patterns-ts) | Every app deploy | `backend-patterns-ts/terraform/` (separate repo) |
| **Layer 2b** | Monitoring (Prometheus, Loki, Tempo, Grafana) | When monitoring config changes | `terraform/monitoring/` (this repo) |

Layer 1 and Layer 2b live in this repo but are separate Terraform states, independently deployable.
Layer 2a lives in its own repo.
All Layer 2 services are tenants on the Layer 1 platform — they share the same VPC, ECS cluster, and ALB.

## Layer 1 — Base Infrastructure

| Component | What it does | Terraform resources | Cost |
|---|---|---|---|
| **S3 Backend** | Terraform state storage | S3 bucket, DynamoDB table | ~$0 |
| **Networking** | Private cloud network | VPC, 2 public + 2 private subnets, IGW, 1 NAT Gateway, route tables | ~$32/month (NAT) |
| **ECS Cluster** | Logical grouping for services | `aws_ecs_cluster`, capacity provider | Free |
| **EC2 ASG** | Machines running containers | Launch template, ASG, ECS-optimized AMI, instance profile | ~$30/month (t3.medium) |
| **ALB** | Single entry point, routes to services by hostname | ALB, HTTP/HTTPS listeners, security group | ~$16/month |
| **DNS + SSL** | Domain + HTTPS | Route53 hosted zone, ACM wildcard cert (`*.yourdomain.com`) | ~$0.50/month |
| **EFS** | Persistent storage for monitoring stack | EFS filesystem, mount targets, security group | ~$1/month |
| **Cognito** | SSO for friends (Google login) | User pool, user pool client, domain | Free (< 50k MAU) |

**Estimated Layer 1 total: ~$80/month**

## Layer 2a — Application (backend-patterns-ts)

Each app creates these resources in its own Terraform:

- ECS service + task definition
- ECR repo (Docker image registry)
- Target group + ALB listener rule (e.g., `api.yourdomain.com`)
- Service-specific IAM task role
- CloudWatch log group
- App-specific resources (SQS, S3, etc.)

Reads Layer 1 outputs via SSM parameters (VPC ID, cluster ARN, ALB ARN, subnet IDs).

## Layer 2b — Monitoring Stack

Four ECS services, all in the same cluster:

| Service | Role |
|---|---|
| **Prometheus** | Metrics collection (scrapes `/metrics` from apps) |
| **Loki** | Log aggregation |
| **Tempo** | Distributed tracing |
| **Grafana** | UI dashboard for all three (accessed via `grafana.yourdomain.com`) |

**OTEL Collector** runs as a sidecar or standalone service — receives logs/traces from apps via OTLP, routes to Loki/Tempo.

## Traffic Flow

```
Internet
  → Route53 (DNS: api.yourdomain.com → ALB)
    → ALB (HTTPS listener, terminates SSL)
      → Listener rule matches hostname
        → Target group → ECS task (private subnet, port 3000)
```

## Communication Between Layers

Layer 1 writes outputs to SSM Parameter Store:
- `/infra/vpc-id`
- `/infra/cluster-arn`
- `/infra/alb-arn`
- `/infra/alb-listener-arn`
- `/infra/private-subnet-ids`
- `/infra/public-subnet-ids`
- `/infra/efs-id`

Layer 2 reads these via `aws_ssm_parameter` data sources — no hard-coded IDs.

## Detailed Docs

- [Networking](./networking.md) — VPC, subnets, IGW, NAT, route tables
- [ECS + EC2 + ALB](./ecs-ec2-alb.md) — Cluster, ASG, load balancer
- [DNS + SSL](./dns-ssl.md) — Route53, ACM certificate
- [EFS](./efs.md) — Persistent storage
- [S3 Backend](./s3-backend.md) — Terraform state storage


---

## Domain

**Domain**: `hari328.net` (purchased from Namecheap)

**Next steps**:
1. Create Route53 hosted zone via Terraform
2. Copy the 4 NS records from Route53
3. Update nameservers on Namecheap to point to Route53
4. Create ACM wildcard cert (`*.hari328.net`) via Terraform

**Services to host**:
- `api.hari328.net` — backend-patterns-ts
- `grafana.hari328.net` — Grafana dashboard
- `prometheus.hari328.net` — Prometheus
