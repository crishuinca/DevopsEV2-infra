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
cd infrastructure/etapa_1
terraform init
terraform apply
terraform output
```

Consola AWS → **ECR** → 3 repositorios `innovatech-*`.

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
cd infrastructure/etapa_2 && terraform destroy
cd infrastructure/etapa_1 && terraform destroy
```
