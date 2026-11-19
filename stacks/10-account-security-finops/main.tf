module "account_guardrails" {
  source = "../../modules/account-guardrails"

  state_bucket_arn     = var.state_bucket_arn
  lock_table_arn       = var.lock_table_arn
  alert_email          = var.alert_email
  allowed_github_repos = var.allowed_github_repos
  budget_limit_usd     = "0.01"
}
