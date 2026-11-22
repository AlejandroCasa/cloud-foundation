terraform {
  backend "s3" {
    # Bucket, region, and dynamodb_table are supplied via -backend-config at init time.
    key     = "services/aegis-mcp/terraform.tfstate"
    encrypt = true
  }
}
