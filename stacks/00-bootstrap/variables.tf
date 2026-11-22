variable "aws_region" {
  description = "Primary AWS region for Terraform remote state resources."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Logical project identifier for tagging."
  type        = string
  default     = "cloud-foundation"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "shared"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for isolated per-project Terraform state files."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "state_bucket_name must be a valid globally unique lowercase S3 bucket name."
  }
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
  default     = "cloud-foundation-tfstate-locks"
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days to retain noncurrent Terraform state versions before expiration."
  type        = number
  default     = 30

  validation {
    condition     = var.noncurrent_version_expiration_days >= 7 && var.noncurrent_version_expiration_days <= 90
    error_message = "noncurrent_version_expiration_days must be between 7 and 90 days."
  }
}
