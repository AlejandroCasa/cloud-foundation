package main

import rego.v1

test_allow_compliant_zero_trust_stack if {
	compliant_input := {"resource": {
		"aws_lambda_function_url": {"app": {"authorization_type": "AWS_IAM"}},
		"aws_s3_bucket_public_access_block": {"tfstate": {
			"block_public_acls": true,
			"block_public_policy": true,
			"ignore_public_acls": true,
			"restrict_public_buckets": true,
		}},
		"aws_cloudfront_distribution": {"app": {"default_cache_behavior": {"viewer_protocol_policy": "redirect-to-https"}}},
	}}
	count(deny) == 0 with input as compliant_input
}

test_deny_public_lambda_function_url if {
	bad_input := {"resource": {"aws_lambda_function_url": {"app": {"authorization_type": "NONE"}}}}
	count(deny) == 1 with input as bad_input
}

test_deny_static_iam_access_key if {
	bad_input := {"resource": {"aws_iam_access_key": {"ci_bot": {"user": "ci-bot"}}}}
	count(deny) == 1 with input as bad_input
}

test_deny_incomplete_s3_public_access_block if {
	bad_input := {"resource": {"aws_s3_bucket_public_access_block": {"tfstate": {
		"block_public_acls": true,
		"block_public_policy": false,
		"ignore_public_acls": true,
		"restrict_public_buckets": true,
	}}}}
	count(deny) == 1 with input as bad_input
}

test_deny_cloudfront_allow_all_http if {
	bad_input := {"resource": {"aws_cloudfront_distribution": {"app": {"default_cache_behavior": [{"viewer_protocol_policy": "allow-all"}]}}}}
	count(deny) == 1 with input as bad_input
}
