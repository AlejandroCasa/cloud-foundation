output "ecr_repository_url" {
  description = "ECR repository URL for container image pushes."
  value       = module.app.ecr_repository_url
}

output "lambda_function_name" {
  description = "Deployed Lambda function name."
  value       = module.app.lambda_function_name
}

output "cloudfront_url" {
  description = "Public HTTPS CloudFront URL."
  value       = module.app.cloudfront_url
}
