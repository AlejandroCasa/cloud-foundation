variable "service_name" {
  description = "Unique lowercase microservice name (e.g., vinum-pulse, finops-sentinel, aegis-mcp)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,32}[a-z0-9]$", var.service_name))
    error_message = "service_name must be lowercase alphanumeric with hyphens (3-34 chars)."
  }
}

variable "environment" {
  description = "Deployment environment (e.g., prod, staging)."
  type        = string
  default     = "prod"
}

variable "image_tag" {
  description = "Immutable container image tag deployed to Lambda from ECR."
  type        = string
  default     = "latest"
}

variable "memory_size" {
  description = "Lambda memory allocation in MB (Graviton2 arm64)."
  type        = number
  default     = 512

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 1024
    error_message = "memory_size must be between 128 MB and 1024 MB to stay within Always-Free GB-s quota."
  }
}

variable "timeout" {
  description = "Lambda execution timeout in seconds."
  type        = number
  default     = 30

  validation {
    condition     = var.timeout >= 5 && var.timeout <= 60
    error_message = "timeout must be between 5 and 60 seconds."
  }
}

variable "reserved_concurrent_executions" {
  description = "Hard DDoS / Denial-of-Wallet concurrency circuit breaker (strictly 1..10)."
  type        = number
  default     = 5

  validation {
    condition     = var.reserved_concurrent_executions >= 1 && var.reserved_concurrent_executions <= 10
    error_message = "reserved_concurrent_executions must be between 1 and 10 to enforce Denial-of-Wallet protection."
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days."
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30], var.log_retention_days)
    error_message = "log_retention_days must be a valid short retention period (1, 3, 5, 7, 14, or 30)."
  }
}

variable "app_port" {
  description = "Port listened to by the FastAPI/Uvicorn container behind AWS Lambda Web Adapter."
  type        = number
  default     = 8000
}

variable "readiness_check_path" {
  description = "Healthcheck endpoint polled by AWS Lambda Web Adapter during cold start."
  type        = string
  default     = "/healthz"
}

variable "environment_variables" {
  description = "Additional non-secret environment variables injected into the Lambda container."
  type        = map(string)
  default     = {}
}
