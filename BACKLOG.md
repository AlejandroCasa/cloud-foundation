# Cloud Foundation — Engineering Backlog

Synced with Obsidian Project Hub (`[[Cloud-Foundation]]`) and `[[ADR-0023-cloud-foundation-zero-cost-aws-iac-and-opa-guardrails]]`.

## Completed (Sprint 2026-W48)
- [x] **[P0]** Initialize multi-project Terraform repository (`>= 1.9`, AWS provider `~> 5.0`), `.gitignore`, `.pre-commit-config.yaml`, `AGENTS.md`, `README.md`.
- [x] **[P0]** Implement `stacks/00-bootstrap` (encrypted versioned S3 tfstate bucket + DynamoDB `PAY_PER_REQUEST` lock table).
- [x] **[P0]** Implement `modules/account-guardrails` & `stacks/10-account-security-finops` (GitHub Actions IAM OIDC provider, least-privilege repo-scoped deploy role, `$0.01 USD` AWS Budget + SNS alert).
- [x] **[P0]** Implement reusable DRY `modules/fastapi-zero-cost-app` (ECR with 1-image lifecycle policy, Graviton2 `arm64` Lambda with `reserved_concurrent_executions` circuit breaker, `AWS_IAM` Function URL, CloudFront OAC SigV4 + HSTS/CSP security headers).
- [x] **[P0]** Provision isolated `stacks/20-services/` definitions for `vinum-pulse`, `finops-sentinel`, and `aegis-mcp`.
- [x] **[P0]** Implement OPA/Rego Policy-as-Code guardrails (`policy/finops_free_tier.rego`, `policy/zero_trust_security.rego`) with full unit test coverage (`opa test` + `conftest`).
- [x] **[P0]** Configure `.github/workflows/ci.yml` (`terraform fmt`, `terraform validate`, `tflint`, `trivy config`, `opa test`, `conftest`).
- [x] **[P1]** Author step-by-step zero-cost AWS bootstrap guide (`docs/AWS-ZERO-COST-BOOTSTRAP.md`).

## Upcoming Priorities
- [ ] **[P1]** Add Terraform plan JSON Conftest verification job to `.github/workflows/ci.yml` once AWS OIDC bootstrap is executed by the repository owner.
- [ ] **[P1]** Add custom domain + ACM TLS certificate (`us-east-1`) optional variables to `modules/fastapi-zero-cost-app` (zero extra AWS cost when using external DNS).
- [ ] **[P2]** Add `infracost` breakdown action in CI to assert `$0.00/mo` projected monthly cost on every Pull Request.
- [ ] **[P2]** Add reusable GitHub Actions composite workflow (`build-push-ecr-lambda.yml`) consumed by `vinum-pulse`, `finops-sentinel`, and `aegis-mcp` via OIDC.
- [ ] **[P2]** Add optional CloudWatch Alarm on Lambda throttles/errors routed to the existing SNS alert topic (within 10 Always-Free CloudWatch alarms).
