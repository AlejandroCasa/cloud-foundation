output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions IAM OIDC provider."
  value       = module.account_guardrails.github_oidc_provider_arn
}

output "github_deploy_role_arn" {
  description = "IAM Role ARN to configure in GitHub Actions aws-actions/configure-aws-credentials@v4."
  value       = module.account_guardrails.github_deploy_role_arn
}

output "billing_alerts_topic_arn" {
  description = "SNS Topic ARN for AWS Budgets billing alerts."
  value       = module.account_guardrails.billing_alerts_topic_arn
}
