# Guía Paso a Paso: Bootstrap AWS Always-Free ($0.00/mes) desde Cero

Esta guía documenta la secuencia manual exacta para pasar de **cero (sin cuenta AWS)** a una fundación cloud **multi-proyecto, Zero-Trust y coste garantizado $0.00/mes** gestionada por `cloud-foundation` y desplegada mediante **GitHub Actions OIDC** (sin claves estáticas `AWS_SECRET_ACCESS_KEY`).

> **Regla de Oro FinOps**: Ningún agente autónomo ejecuta `terraform apply`. Los pasos 1 a 5 los ejecutas tú una sola vez desde tu terminal local para inicializar el backend remoto, el proveedor OIDC y la alarma de presupuesto de `$0.01 USD`.

---

## Paso 1: Crear la Cuenta AWS desde Cero y Proteger el Usuario `root` con MFA

1. Accede a [https://aws.amazon.com/](https://aws.amazon.com/) y selecciona **Create an AWS Account** (Plan **Basic Support — Free**).
   - Usa un correo principal exclusivo o con alias dedicado (ej. `tu.correo+aws-prod@gmail.com`).
   - AWS solicita una tarjeta bancaria para verificación de identidad; no cobra cargos en los servicios Always-Free configurados en este repositorio.
2. Nada más iniciar sesión como usuario **`root`**, activa **MFA obligatorio**:
   - Ve a **IAM** → **Dashboard** → **Add MFA for root user**.
   - Configura una **Authenticator App** (Authy, 1Password, Google Authenticator) o una **Passkey / YubiKey**.
   - **Nunca** generes Access Keys para el usuario `root`.

---

## Paso 2: Activar Alertas de Free Tier y Preferencias de Facturación en Consola

Antes de provisionar ningún recurso, activa la primera capa de defensa financiera directamente en la consola de AWS:

1. Ve a **Billing and Cost Management** → **Billing preferences**.
2. Activa las tres casillas de **Alert preferences**:
   - `Receive AWS Free Tier alerts` (introduce tu email de alertas).
   - `Receive CloudWatch billing alerts`.
   - `Receive PDF Invoice By Email` (opcional, recomendado para auditoría mensual).
3. Pulsa **Update** para guardar.

---

## Paso 3: Crear un Perfil IAM Temporal de Bootstrap (y Eliminarlo al Terminar)

Para ejecutar únicamente los dos stacks iniciales (`00-bootstrap` y `10-account-security-finops`), crea una identidad temporal con credenciales efímeras (recomendado: **IAM Identity Center / AWS SSO**; alternativa rápida: usuario IAM temporal `bootstrap-admin` que **eliminarás en el Paso 5**):

### Opción Recomendada (IAM Identity Center — Zero Claves Permanentes)
1. En la consola AWS (`eu-west-1`), abre **IAM Identity Center** → **Enable**.
2. Crea tu usuario personal y asígnale el Permission Set `AdministratorAccess` sobre tu cuenta.
3. En tu terminal WSL 2, configura AWS CLI v2:
   ```bash
   aws configure sso --profile cloud-foundation-bootstrap
   aws sts get-caller-identity --profile cloud-foundation-bootstrap
   ```

### Opción Alternativa (Usuario IAM Temporal de Un Solo Uso)
1. Crea un usuario IAM `temp-bootstrap` con acceso CLI temporal y política `AdministratorAccess`.
2. Configura `aws configure --profile cloud-foundation-bootstrap` (región `eu-west-1`).
3. **Obligatorio**: En cuanto finalices el Paso 5 y verifiques GitHub OIDC, **desactiva y elimina** las Access Keys y el usuario `temp-bootstrap`.

---

## Paso 4: Ejecutar `stacks/00-bootstrap` (S3 Remote `tfstate` + DynamoDB Lock)

Este stack crea el bucket S3 cifrado (`AES256`, versionado, 100% privado, expiración de versiones antiguas a 30 días) y la tabla DynamoDB `PAY_PER_REQUEST` para bloqueo de estado.

```bash
cd /mnt/c/Workspace/cloud-foundation/stacks/00-bootstrap

# 1. Crea tu archivo local (ignorado por .gitignore)
cp terraform.tfvars.example terraform.tfvars
# Edita terraform.tfvars y define un state_bucket_name único globalmente

# 2. Inicializa, revisa el plan y aplica
export AWS_PROFILE=cloud-foundation-bootstrap
terraform init
terraform plan -out=bootstrap.tfplan
terraform apply bootstrap.tfplan

# 3. Guarda los outputs (los necesitarás en el Paso 5)
terraform output
```

Anota los valores devueltos:
- `state_bucket_name`
- `state_bucket_arn`
- `lock_table_name`
- `lock_table_arn`

---

## Paso 5: Ejecutar `stacks/10-account-security-finops` (GitHub OIDC + Presupuesto `$0.01 USD`)

Este stack aprovisiona:
- El proveedor **IAM OIDC** singleton para `token.actions.githubusercontent.com`.
- El rol IAM de mínimo privilegio (`github-actions-cloud-foundation-deploy`) restringido exclusivamente a `AlejandroCasa/{vinum-pulse,finops-sentinel,aegis-mcp,cloud-foundation}`.
- El **AWS Budget de `$0.01 USD`** (alertas `ACTUAL` y `FORECASTED`) conectado a un tópico SNS cifrado.

```bash
cd /mnt/c/Workspace/cloud-foundation/stacks/10-account-security-finops

# 1. Configura tus variables locales
cp terraform.tfvars.example terraform.tfvars
# Rellena state_bucket_arn, lock_table_arn y alert_email

# 2. Inicializa conectando al backend remoto S3 recién creado
export AWS_PROFILE=cloud-foundation-bootstrap
terraform init   -backend-config="bucket=<TU_STATE_BUCKET_NAME>"   -backend-config="region=eu-west-1"   -backend-config="dynamodb_table=cloud-foundation-tfstate-locks"

# 3. Revisa y aplica
terraform plan -out=guardrails.tfplan
terraform apply guardrails.tfplan

# 4. Obtén el ARN del rol OIDC para GitHub Actions
terraform output github_deploy_role_arn
```

### Verificación Obligatoria Post-Paso 5
1. **Confirma el correo de AWS SNS**: Abre tu bandeja de entrada y pulsa **Confirm subscription** en el correo de `AWS Notification - Subscription Confirmation`. Sin este clic, las alertas del presupuesto de `$0.01 USD` no se entregarán.
2. **Elimina las credenciales temporales de bootstrap**: Si creaste un usuario IAM `temp-bootstrap` en el Paso 3, bórralo ahora en IAM. A partir de este momento, el despliegue opera 100% vía OIDC efímero.

---

## Paso 6: Conectar GitHub Actions vía OIDC y Desplegar `vinum-pulse`

1. En cada repositorio de GitHub (`vinum-pulse`, `finops-sentinel`, `aegis-mcp`, `cloud-foundation`), añade en **Settings → Secrets and variables → Actions → Variables** (no son secretos críticos, son identificadores de configuración):
   - `AWS_REGION`: `eu-west-1`
   - `AWS_DEPLOY_ROLE_ARN`: `<output github_deploy_role_arn del Paso 5>`
   - `TF_STATE_BUCKET`: `<TU_STATE_BUCKET_NAME>`
   - `TF_LOCK_TABLE`: `cloud-foundation-tfstate-locks`

2. En tu workflow de GitHub Actions, autentícate **sin claves estáticas** usando OIDC:

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - name: Configure AWS Credentials via OIDC
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ vars.AWS_DEPLOY_ROLE_ARN }}
      aws-region: ${{ vars.AWS_REGION }}
```

3. Para desplegar el primer servicio (`stacks/20-services/vinum-pulse`):
   - Construye y publica la imagen `linux/arm64` (con **AWS Lambda Web Adapter**) en el repositorio ECR creado por el módulo.
   - Inicializa y aplica `stacks/20-services/vinum-pulse` pasando `-backend-config` (su estado quedará aislado en `services/vinum-pulse/terraform.tfstate`).
   - Obtén la URL pública segura con `terraform output cloudfront_url` (HTTPS TLS 1.2+, HSTS, AWS Shield Standard y Lambda Function URL protegida por `AWS_IAM` + CloudFront OAC SigV4).
