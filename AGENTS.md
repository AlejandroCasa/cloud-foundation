# Cloud Foundation — Repository Engineering Rules

Inherits global CTO governance from `c:/Workspace/AGENTS.md`.

## 1. Repository Architecture & Scope
- **Purpose**: Central multi-project Infrastructure as Code (IaC) & Policy-as-Code repository provisioning an **AWS Always-Free ($0.00/month)** serverless architecture for portfolio microservices (`vinum-pulse`, `finops-sentinel`, `aegis-mcp`).
- **IaC Toolchain**: Terraform `>= 1.9`, AWS Provider `~> 5.0`, OPA/Rego (`conftest` + `opa test`), `tflint`, and `trivy config`.
- **Layout**:
  - `stacks/00-bootstrap/`: Remote S3 state bucket + DynamoDB lock table.
  - `modules/account-guardrails/` & `stacks/10-account-security-finops/`: Singleton GitHub Actions IAM OIDC provider, least-privilege deploy role, and `$0.01 USD` AWS Budget + SNS alert.
  - `modules/fastapi-zero-cost-app/`: DRY reusable module (ECR with 1-image lifecycle policy + Graviton2 `arm64` Lambda container + `AWS_IAM` Function URL + CloudFront OAC SigV4 + Security Response Headers).
  - `stacks/20-services/<service>/`: Isolated per-service state backends (`services/<name>/terraform.tfstate`).
  - `policy/`: OPA/Rego FinOps Free-Tier and Zero-Trust Security guardrails + unit tests.
  - `docs/AWS-ZERO-COST-BOOTSTRAP.md`: Step-by-step bootstrap guide from a brand-new AWS account.

## 2. Hard Guardrail (Zero Exceptions)
- **NEVER run `terraform apply`, `tofu apply`, `terraform destroy`, or any command that mutates real AWS infrastructure in autonomous mode.**
- Only static validation (`terraform fmt`, `terraform validate`, `tflint`, `trivy config`, `conftest test`, `opa test`) is permitted autonomously.

## 3. Mandatory Static Quality Gates
Run via WSL 2 / Docker from `/mnt/c/Workspace/cloud-foundation`:
1. `terraform fmt -check -recursive`
2. `terraform init -backend=false && terraform validate` across every module and stack
3. `opa test policy/ -v`
4. `conftest test --policy policy/ modules stacks`
5. `trivy config --exit-code 1 --severity HIGH,CRITICAL .`

## 4. Obsidian Knowledge Links
- **Project Hub**: `c:/Workspace/docs/Proyectos/Cloud-Foundation.md` (`[[Cloud-Foundation]]`)
- **Technical Spec**: `c:/Workspace/docs/Proyectos/Cloud-Foundation-Spec.md` (`[[Cloud-Foundation-Spec]]`)
- **ADR**: `c:/Workspace/docs/Arquitectura/ADR-0023-cloud-foundation-zero-cost-aws-iac-and-opa-guardrails.md`
