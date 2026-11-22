terraform {
  backend "s3" {
    # Bucket, region, and dynamodb_table are supplied via -backend-config at init time
    # to avoid hardcoding account-specific bucket names in version control.
    key     = "account/security-finops/terraform.tfstate"
    encrypt = true
  }
}
