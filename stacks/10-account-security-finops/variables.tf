variable "aws_region" {
  description = "Primary AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Logical project identifier for tagging."
  type        = string
  default     = "cloud-foundation"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "shared"
}

variable "state_bucket_arn" {
  description = "ARN of the remote Terraform state S3 bucket created in stacks/00-bootstrap."
  type        = string
}

variable "lock_table_arn" {
  description = "ARN of the remote Terraform lock DynamoDB table created in stacks/00-bootstrap."
  type        = string
}

variable "alert_email" {
  description = "Email address for $0.01 USD AWS Budget notifications."
  type        = string
}

variable "allowed_github_repos" {
  description = "GitHub repository subject claims authorized to assume the OIDC deploy role."
  type        = list(string)
  default = [
    "repo:AlejandroCasa/vinum-pulse:*",
    "repo:AlejandroCasa/finops-sentinel:*",
    "repo:AlejandroCasa/aegis-mcp:*",
    "repo:AlejandroCasa/cloud-foundation:*",
  ]
}
