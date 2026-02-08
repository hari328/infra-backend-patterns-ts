variable "role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = "github-actions-app-deploy"
}

variable "github_repositories" {
  description = "List of GitHub repo patterns allowed to assume this role (sub claim)"
  type        = list(string)
  default     = ["repo:hari328/backend-patterns-ts:*"]
}

