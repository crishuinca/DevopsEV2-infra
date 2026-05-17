# Infraestructura Innovatech

Misma idea que `academia-304d-main/infra`: **etapa_1** crea ECR, **etapa_2** crea red y EC2.

## Requisitos

- AWS Academy Learner Lab activo
- AWS CLI y Terraform instalados

## 1. Credenciales

```bash
aws configure
aws configure set aws_session_token TU_SESSION_TOKEN
aws sts get-caller-identity
```

## 2. Etapa 1 — ECR

```bash
cd etapa_1
terraform init
terraform apply
terraform output
```

Consola AWS → **ECR** → 3 repositorios `innovatech-*`.

| Output | Uso |
|--------|-----|
| `ecr_registry` | Secret `ECR_REGISTRY` en GitHub (ventas, despachos, frontend) |
| `ecr_ventas` / `ecr_despachos` / `ecr_frontend` | URLs completas de cada repositorio |

## 3. Etapa 2 — VPC + EC2

```bash
cd ../etapa_2
terraform init
terraform apply
terraform output
```

Consola AWS → **EC2** (3 instancias), **VPC**, **Security Groups**.

| Output | Uso |
|--------|-----|
| `frontend_public_ip` | Web + EC2_HOST frontend |
| `backend_public_ip` | EC2_HOST backends |
| `database_private_ip` | DB_ENDPOINT en contenedores |

## Destruir

```bash
cd etapa_2 && terraform destroy
cd ../etapa_1 && terraform destroy
```

## Secrets en GitHub Actions (cada repo de app)

En **Settings → Secrets → Actions**, configura (no uses Docker Hub):

| Secret | Origen |
|--------|--------|
| `AWS_ACCESS_KEY_ID` | Learner Lab |
| `AWS_SECRET_ACCESS_KEY` | Learner Lab |
| `AWS_SESSION_TOKEN` | Learner Lab (obligatorio en Academy) |
| `AWS_REGION` | Ej. `us-east-1` |
| `ECR_REGISTRY` | `terraform output -raw ecr_registry` (etapa_1) |
| `EC2_HOST` | IP pública de la instancia donde despliegas |
| `EC2_USER` | `ec2-user` (Amazon Linux 2) |
| `SSH_PRIVATE_KEY` | Contenido del `.pem` (vockey) |
