# EFS — Persistent Storage for Containers

## Why
ECS tasks are ephemeral — when a container restarts, its data is gone. Loki, Prometheus, and Tempo need persistent storage for their data.

## What you create

| Resource | Purpose |
|---|---|
| `aws_efs_file_system` | The shared filesystem |
| `aws_efs_mount_target` | One per private subnet (2 total) — so containers in any AZ can access it |
| `aws_security_group` | Allow NFS traffic (port 2049) from ECS instances only |

## How it works
- EFS is like a network drive that multiple containers can mount simultaneously
- ECS task definitions reference the EFS filesystem ID
- The container mounts it at a path (e.g., `/data`)
- Data persists across container restarts, deployments, and even instance replacements

## Cost
- $0.30/GB/month for standard storage
- For monitoring stack data (small project) — likely under $1/month

