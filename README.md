# InnovaTech — Infraestructura Terraform (AWS)

**Descripción**  
Infraestructura como código para el EP2 DevOps (ISY1101). Provisiona repositorios **ECR**, VPC con subredes, **3 instancias EC2** (frontend, backend, database) y security groups. Los outputs alimentan los secrets de GitHub Actions en los repos de aplicaciones.

---

## 🧭 Estructura del proyecto

```
infra/
├── etapa_1/
│   ├── main.tf           # Repositorios ECR (3)
│   ├── outputs.tf        # ecr_registry, URLs
│   └── variables.tf
├── etapa_2/
│   ├── main.tf           # VPC, EC2, SG, user_data
│   ├── outputs.tf        # IPs públicas/privadas
│   └── variables.tf
├── terraform.tfvars.example
└── README.md
```

> `terraform.tfvars` y `*.tfstate` no se suben a Git (ver `.gitignore`).

---

## 🚀 Requisitos

- Terraform CLI >= 1.0
- AWS CLI configurado
- **AWS Academy Learner Lab** activo (Access Key, Secret, **Session Token**)
- Par de claves **`vockey`** en la consola EC2 (`key_pair_name` en tfvars)
- Provider: `hashicorp/aws` ~> 5.x

---

## ⚙️ Flujo de uso

1. Clona el repositorio.
2. Configura credenciales del lab:

```bash
aws configure
aws configure set aws_session_token TU_SESSION_TOKEN
aws sts get-caller-identity
```

3. **Etapa 1 — ECR:**

```bash
cd etapa_1
terraform init
terraform apply
terraform output
```

4. **Etapa 2 — Red y EC2:**

```bash
cd ../etapa_2
cp ../terraform.tfvars.example terraform.tfvars
# Editar key_pair_name = "vockey"
terraform init
terraform apply
terraform output
```

5. Copia outputs a secrets de GitHub (tabla abajo).
6. Despliega apps (push a `deploy` en ventas → despachos → frontend).

**Destruir** (solo al cerrar el lab):

```bash
cd etapa_2 && terraform destroy
cd ../etapa_1 && terraform destroy
```

---

## 📦 ¿Qué despliega este proyecto?

| Etapa | Recursos |
|-------|----------|
| **etapa_1** | 3 repos ECR: `innovatech-frontend`, `innovatech-backend-ventas`, `innovatech-backend-despachos` |
| **etapa_2** | VPC, subnets pública/privada, NAT, 3× EC2 `t2.micro`, security groups |

| Output | Uso |
|--------|-----|
| `ecr_registry` | Secret `ECR_REGISTRY` |
| `frontend_public_ip` | URL web + `EC2_HOST` (frontend) |
| `backend_public_ip` | `EC2_HOST` (backends) + SSH deploy |
| `backend_private_ip` | `DB_PRIVATE_IP`, `BACKEND_HOST` |

MySQL en producción corre en la **EC2 backend** (contenedor `mysql-innovatech`), no en la instancia database del diagrama inicial del curso.

---

## 🧭 Diagrama de arquitectura

```
Internet
   │
   ▼
[ EC2 Frontend ] ──SG──► [ EC2 Backend :8081 / :8082 ]
   puerto 80              │
                           ├── MySQL mysql-innovatech :3306
                           └── (IP privada en VPC)
[ EC2 Database ]  (subred privada; SG restringido)
```

---

## 📌 Mejores prácticas incluidas

- Infra en dos etapas: ECR independiente del ciclo de vida de EC2.
- Variables en `terraform.tfvars.example`; valores reales fuera de Git.
- Outputs documentados para no hardcodear IPs en los repos de apps.
- SG: solo HTTP(80) y SSH al front; APIs backend solo desde el SG del frontend.
- Clave SSH: par **`vockey`** en AWS; archivo descargado del lab (`labsuser.pem`) → secret `SSH_PRIVATE_KEY`.

### Secrets GitHub (repos ventas, despachos, frontend)

| Secret | Origen |
|--------|--------|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` | Learner Lab |
| `AWS_REGION` | ej. `us-east-1` |
| `ECR_REGISTRY` | `terraform output -raw ecr_registry` (etapa_1) |
| `EC2_USER` | `ec2-user` |
| `SSH_PRIVATE_KEY` | Contenido completo de `labsuser.pem` (no subir a Git) |
| `EC2_HOST` | `backend_public_ip` o `frontend_public_ip` según repo |
| `DB_PRIVATE_IP` | `backend_private_ip` (backends) |
| `BACKEND_HOST` | `backend_private_ip` (solo frontend) |

---

## 🔧 Cómo extender este proyecto

- Módulos Terraform (`modules/network`, `modules/compute`).
- Backend remoto (S3 + DynamoDB lock) — no disponible en todos los labs.
- RDS en lugar de MySQL en contenedor.
- ALB + target groups delante de las EC2.
- Variables por ambiente (`dev` / `prod` tfvars).
