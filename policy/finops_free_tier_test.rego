package main

import rego.v1

test_allow_compliant_always_free_stack if {
	compliant_input := {"resource": {
		"aws_ecr_repository": {"app": {"name": "vinum-pulse-prod"}},
		"aws_ecr_lifecycle_policy": {"keep_latest": {"repository": "vinum-pulse-prod"}},
		"aws_lambda_function": {"app": {
			"architectures": ["arm64"],
			"reserved_concurrent_executions": 5,
		}},
	}}
	count(deny) == 0 with input as compliant_input
}

test_deny_paid_nat_gateway if {
	bad_input := {"resource": {"aws_nat_gateway": {"main": {"subnet_id": "subnet-123"}}}}
	count(deny) == 1 with input as bad_input
}

test_deny_paid_rds_and_alb if {
	bad_input := {"resource": {
		"aws_db_instance": {"pg": {"instance_class": "db.t3.micro"}},
		"aws_alb": {"web": {"internal": false}},
	}}
	count(deny) == 2 with input as bad_input
}

test_deny_paid_eks_and_ecs if {
	bad_input := {"resource": {
		"aws_eks_cluster": {"k8s": {"name": "prod"}},
		"aws_ecs_service": {"api": {"name": "api"}},
		"aws_elasticache_cluster": {"redis": {"cluster_id": "redis"}},
	}}
	count(deny) == 3 with input as bad_input
}

test_deny_lambda_missing_concurrency_cap if {
	bad_input := {"resource": {"aws_lambda_function": {"app": {"architectures": ["arm64"]}}}}
	count(deny) == 1 with input as bad_input
}

test_deny_lambda_concurrency_cap_too_high if {
	bad_input := {"resource": {"aws_lambda_function": {"app": {
		"architectures": ["arm64"],
		"reserved_concurrent_executions": 50,
	}}}}
	count(deny) == 1 with input as bad_input
}

test_deny_lambda_concurrency_cap_zero if {
	bad_input := {"resource": {"aws_lambda_function": {"app": {
		"architectures": ["arm64"],
		"reserved_concurrent_executions": 0,
	}}}}
	count(deny) == 1 with input as bad_input
}

test_deny_lambda_x86_64_architecture if {
	bad_input := {"resource": {"aws_lambda_function": {"app": {
		"architectures": ["x86_64"],
		"reserved_concurrent_executions": 5,
	}}}}
	count(deny) == 1 with input as bad_input
}

test_deny_ecr_without_lifecycle_policy if {
	bad_input := {"resource": {"aws_ecr_repository": {"app": {"name": "orphan-repo"}}}}
	count(deny) == 1 with input as bad_input
}
