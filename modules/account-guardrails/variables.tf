variable "allowed_github_repos" {
  description = "List of GitHub repository subject claims permitted to assume the OIDC deploy role."
  type        = list(string)
  default = [
    "repo:AlejandroCasa/vinum-pulse:*",
    "repo:AlejandroCasa/finops-sentinel:*",
    "repo:AlejandroCasa/aegis-mcp:*",
    "repo:AlejandroCasa/cloud-foundation:*",
  ]

  validation {
    condition     = length(var.allowed_github_repos) > 0
    error_message = "At least one GitHub repository subject claim must be specified."
  }
}

variable "deploy_role_name" {
  description = "Name of the least-privilege IAM role assumed by GitHub Actions via OIDC."
  type        = string
  default     = "github-actions-cloud-foundation-deploy"
}

variable "state_bucket_arn" {
  description = "ARN of the Terraform remote state S3 bucket."
  type        = string
}

variable "lock_table_arn" {
  description = "ARN of the Terraform remote state DynamoDB lock table."
  type        = string
}

variable "alert_email" {
  description = "Email address subscribed to the SNS topic for $0.01 USD AWS Budget alerts."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "budget_limit_usd" {
  description = "Monthly AWS Budget threshold in USD (hard default: 0.01 USD)."
  type        = string
  default     = "0.01"

  validation {
    condition     = tonumber(var.budget_limit_usd) > 0 && tonumber(var.budget_limit_usd) <= 1.00
    error_message = "budget_limit_usd must be between 0.01 and 1.00 USD to protect Always-Free tier."
  }
}

variable "service_resource_prefixes" {
  description = "Allowed resource name prefixes managed by the CI/CD deploy role."
  type        = list(string)
  default     = ["vinum-pulse", "finops-sentinel", "aegis-mcp", "cloud-foundation"]
}
