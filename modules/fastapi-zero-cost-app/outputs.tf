output "ecr_repository_url" {
  description = "ECR repository URL for pushing arm64 container images."
  value       = aws_ecr_repository.app.repository_url
}

output "lambda_function_name" {
  description = "Name of the Graviton2 Lambda function."
  value       = aws_lambda_function.app.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Graviton2 Lambda function."
  value       = aws_lambda_function.app.arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.app.id
}

output "cloudfront_url" {
  description = "Public HTTPS CloudFront URL fronting the AWS_IAM Lambda Function URL."
  value       = "https://${aws_cloudfront_distribution.app.domain_name}"
}
