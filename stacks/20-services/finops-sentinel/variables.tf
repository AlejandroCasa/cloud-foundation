variable "aws_region" {
  description = "AWS region for finops-sentinel deployment."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Logical project identifier for tagging."
  type        = string
  default     = "finops-sentinel"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "prod"
}

variable "image_tag" {
  description = "Immutable ECR container image tag to deploy."
  type        = string
  default     = "latest"
}

variable "reserved_concurrent_executions" {
  description = "Hard Lambda concurrency circuit breaker (1..10)."
  type        = number
  default     = 5
}
