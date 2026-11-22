package main

import rego.v1

# 1. Forbid unauthenticated Lambda Function URLs (must be AWS_IAM behind CloudFront OAC SigV4).
deny contains msg if {
	some name, raw_cfg in object.get(object.get(input, "resource", {}), "aws_lambda_function_url", {})
	some cfg in normalize_blocks(raw_cfg)
	auth := object.get(cfg, "authorization_type", "NONE")
	auth != "AWS_IAM"
	msg := sprintf("Zero-Trust violation: aws_lambda_function_url.%s must use authorization_type = 'AWS_IAM' (found: '%s').", [name, auth])
}

# 2. Forbid static IAM user access keys (enforce GitHub OIDC short-lived federation).
deny contains msg if {
	some name, _ in object.get(object.get(input, "resource", {}), "aws_iam_access_key", {})
	msg := sprintf("Zero-Trust violation: static IAM key aws_iam_access_key.%s is strictly forbidden; use IAM OIDC federation.", [name])
}

# 3. Enforce all four S3 Public Access Block flags are true.
required_s3_public_block_flags := [
	"block_public_acls",
	"block_public_policy",
	"ignore_public_acls",
	"restrict_public_buckets",
]

deny contains msg if {
	some name, raw_cfg in object.get(object.get(input, "resource", {}), "aws_s3_bucket_public_access_block", {})
	some cfg in normalize_blocks(raw_cfg)
	some flag in required_s3_public_block_flags
	object.get(cfg, flag, false) != true
	msg := sprintf("Zero-Trust violation: aws_s3_bucket_public_access_block.%s must set %s = true.", [name, flag])
}

# 4. Forbid CloudFront distributions allowing unencrypted HTTP (allow-all).
deny contains msg if {
	some name, raw_cfg in object.get(object.get(input, "resource", {}), "aws_cloudfront_distribution", {})
	some cfg in normalize_blocks(raw_cfg)
	some behavior in normalize_blocks(object.get(cfg, "default_cache_behavior", []))
	object.get(behavior, "viewer_protocol_policy", "allow-all") == "allow-all"
	msg := sprintf("Zero-Trust violation: aws_cloudfront_distribution.%s must not use viewer_protocol_policy = 'allow-all'; enforce HTTPS.", [name])
}

normalize_blocks(val) := val if {
	is_array(val)
}

normalize_blocks(val) := [val] if {
	is_object(val)
}
