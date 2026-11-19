output "github_oidc_provider_arn" {
  description = "ARN of the singleton GitHub Actions IAM OIDC provider."
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "github_deploy_role_arn" {
  description = "ARN of the least-privilege IAM role for GitHub Actions OIDC deployments."
  value       = aws_iam_role.github_actions_deploy.arn
}

output "billing_alerts_topic_arn" {
  description = "ARN of the SNS topic receiving $0.01 USD AWS Budget notifications."
  value       = aws_sns_topic.billing_alerts.arn
}

output "budget_name" {
  description = "Name of the $0.01 USD monthly AWS Budget."
  value       = aws_budgets_budget.zero_cost_guardrail.name
}
