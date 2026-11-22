package main

import rego.v1

# Forbidden paid AWS resource types that violate the $0.00/mo Always-Free architecture.
forbidden_paid_resources := {
	"aws_nat_gateway",
	"aws_lb",
	"aws_alb",
	"aws_db_instance",
	"aws_rds_cluster",
	"aws_ecs_service",
	"aws_eks_cluster",
	"aws_elasticache_cluster",
}

# 1. Block paid AWS primitives (NAT Gateway, ALB/NLB, RDS, ECS, EKS, ElastiCache).
deny contains msg if {
	some resource_type, resources in object.get(input, "resource", {})
	forbidden_paid_resources[resource_type]
	some name, _ in resources
	msg := sprintf("FinOps violation: paid resource '%s.%s' is forbidden in Always-Free ($0.00/mo) foundation.", [resource_type, name])
}

# 2. Enforce Lambda reserved_concurrent_executions is explicitly configured (Denial-of-Wallet circuit breaker).
deny contains msg if {
	some name, raw_cfg in object.get(object.get(input, "resource", {}), "aws_lambda_function", {})
	some cfg in normalize_blocks(raw_cfg)
	not has_key(cfg, "reserved_concurrent_executions")
	msg := sprintf("FinOps violation: aws_lambda_function.%s must define reserved_concurrent_executions (1..15) as a Denial-of-Wallet circuit breaker.", [name])
}

# 3. Enforce numeric reserved_concurrent_executions is within [1, 15].
deny contains msg if {
	some name, raw_cfg in object.get(object.get(input, "resource", {}), "aws_lambda_function", {})
	some cfg in normalize_blocks(raw_cfg)
	val := cfg.reserved_concurrent_executions
	is_number(val)
	val <= 0
	msg := sprintf("FinOps violation: aws_lambda_function.%s reserved_concurrent_executions (%v) must be > 0.", [name, val])
}

deny contains msg if {
	some name, raw_cfg in object.get(object.get(input, "resource", {}), "aws_lambda_function", {})
	some cfg in normalize_blocks(raw_cfg)
	val := cfg.reserved_concurrent_executions
	is_number(val)
	val > 15
	msg := sprintf("FinOps violation: aws_lambda_function.%s reserved_concurrent_executions (%v) exceeds hard Free-Tier cap of 15.", [name, val])
}

# 4. Enforce Graviton2 arm64 architecture on all Lambda functions.
deny contains msg if {
	some name, raw_cfg in object.get(object.get(input, "resource", {}), "aws_lambda_function", {})
	some cfg in normalize_blocks(raw_cfg)
	archs := object.get(cfg, "architectures", [])
	not contains_arm64(archs)
	msg := sprintf("FinOps violation: aws_lambda_function.%s must use Graviton2 architecture ['arm64'] (found: %v).", [name, archs])
}

# 5. Enforce ECR lifecycle policy accompanies every ECR repository (500 MB Free-Tier quota).
deny contains msg if {
	repos := object.get(object.get(input, "resource", {}), "aws_ecr_repository", {})
	count(repos) > 0
	policies := object.get(object.get(input, "resource", {}), "aws_ecr_lifecycle_policy", {})
	count(policies) == 0
	some name, _ in repos
	msg := sprintf("FinOps violation: aws_ecr_repository.%s must have an accompanying aws_ecr_lifecycle_policy to stay under the 500 MB Free-Tier quota.", [name])
}

has_key(obj, k) if {
	_ = obj[k]
}

contains_arm64(archs) if {
	some a in archs
	a == "arm64"
}
