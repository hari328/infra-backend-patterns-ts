# Networking

The foundation of everything. Nothing works without this.

## What you're building

A private network in AWS with controlled internet access.

## Components

### 1. VPC (Virtual Private Cloud)
- Your isolated network in AWS
- You pick a CIDR block (e.g., `10.0.0.0/16`) — gives you 65,536 IP addresses
- Everything else lives inside this

### 2. Subnets
Split the VPC across Availability Zones for high availability:

| Subnet | AZ | CIDR | What goes here |
|---|---|---|---|
| Public Subnet A | us-east-1a | `10.0.1.0/24` | ALB, NAT Gateway |
| Public Subnet B | us-east-1b | `10.0.2.0/24` | ALB, NAT Gateway (redundancy) |
| Private Subnet A | us-east-1a | `10.0.10.0/24` | ECS tasks, RDS |
| Private Subnet B | us-east-1b | `10.0.20.0/24` | ECS tasks, RDS |

### 3. Internet Gateway (IGW)
- Attaches to the VPC
- Gives public subnets direct internet access (both inbound and outbound)
- Without this, your VPC is completely dark — no internet at all

### 4. NAT Gateway
- Sits in a public subnet
- Lets private subnet resources reach the internet (outbound only)
- Your ECS tasks use this to pull Docker images, call external APIs, etc.
- Nothing from the internet can initiate a connection back through it
- You pay ~$0.045/hr per NAT Gateway (~$32/month)

### 5. Route Tables
Rules that tell traffic where to go:

**Public subnet route table:**
| Destination | Target |
|---|---|
| `10.0.0.0/16` | local (stays in VPC) |
| `0.0.0.0/0` | Internet Gateway |

**Private subnet route table:**
| Destination | Target |
|---|---|
| `10.0.0.0/16` | local (stays in VPC) |
| `0.0.0.0/0` | NAT Gateway |

## Traffic flow

```
Inbound (user hits your API):
  Internet → IGW → Public Subnet → ALB → Private Subnet → ECS Task

Outbound (your app calls an external API):
  ECS Task → Private Subnet → NAT Gateway (in Public Subnet) → IGW → Internet
```

## Terraform resources involved

- `aws_vpc`
- `aws_subnet` (x4 — 2 public, 2 private)
- `aws_internet_gateway`
- `aws_nat_gateway` + `aws_eip` (NAT needs an Elastic IP)
- `aws_route_table` (x2 — one public, one private)
- `aws_route_table_association` (x4 — link each subnet to its route table)

## Cost
- VPC, subnets, IGW, route tables — **free**
- NAT Gateway — ~$32/month + data transfer costs
- Elastic IP (when attached to NAT) — **free** (only costs if unattached)

