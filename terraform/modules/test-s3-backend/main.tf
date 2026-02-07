data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "message" {
  value = "S3 backend is working! Connected to account ${data.aws_caller_identity.current.account_id}"
}

