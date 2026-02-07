# S3 Backend — Terraform State Storage

## Why
Terraform needs to store its state file somewhere shared and safe. Local state files don't work when multiple people or CI/CD pipelines run Terraform.

## What you create

| Resource | Purpose |
|---|---|
| `aws_s3_bucket` | Stores the `.tfstate` file |
| `aws_s3_bucket_versioning` | Keeps history of every state change — rollback safety |
| `aws_s3_bucket_server_side_encryption_configuration` | Encrypts state at rest (contains secrets) |
| `aws_dynamodb_table` | State locking — prevents two people from running Terraform at the same time |

## Bootstrap problem
This is the one chicken-and-egg in Terraform: you need the S3 bucket to exist before you can store state in it. 

Two approaches:
1. Create the bucket manually in AWS console first, then reference it in Terraform backend config
2. Create it with Terraform using local state first, then migrate to S3 backend

## Cost
- S3 — pennies (state files are tiny)
- DynamoDB — free tier covers it (25 read/write capacity units)

## Note
This is created **once per AWS account**, not per environment. All Terraform states (Layer 1, app, monitoring) can share the same bucket — they use different state file keys (paths).

