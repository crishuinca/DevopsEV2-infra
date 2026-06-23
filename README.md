# InnovaTech — Infraestructura Terraform (AWS)

**Descripción**  
Infraestructura como código para el EP3 DevOps (ISY1101). Provisiona repositorios **ECR**, un clúster **EKS** con nodos worker, y manifiestos **Kubernetes** para frontend, backends y MySQL. El pipeline central en GitHub Actions construye las imágenes, las publica en ECR y despliega en EKS al hacer push a la rama `deploy`.

---

## 🧭 Estructura del proyecto

```
DevopsEV2-infra/
├── etapa_1/
│   ├── main.tf           # Repositorios ECR (3)
│   ├── outputs.tf        # ecr_registry, URLs
│   └── variables.tf
├── etapa_3/
│   ├── main.tf           # VPC, EKS cluster, node group
│   ├── outputs.tf        # cluster_name, configure_kubectl
│   └── variables.tf
├── k8s/
│   ├── frontend.yml              # Deployment + Service LoadBalancer
│   ├── backend-ventas.yml        # Deployment + Service ClusterIP
│   ├── backend-despachos.yml
│   ├── mysql.yml                 # Deployment + ConfigMap init
│   ├── secrets.yml               # db-credentials
│   ├── metrics-server.yml        # Requerido por HPA
│   ├── hpa-backend-ventas.yml
│   └── hpa-backend-despachos.yml
├── .github/workflows/cd.yml      # Pipeline EKS (build + deploy)
├── etapa_2/                      # Legacy EP2 (EC2) — no usar en EV3
├── terraform.tfvars.example
└── README.md
```

> `terraform.tfvars` y `*.tfstate` no se suben a Git (ver `.gitignore`).

---

## 🚀 Requisitos

- Terraform CLI >= 1.0
- AWS CLI configurado
- **AWS Academy Learner Lab** activo (Access Key, Secret, **Session Token**)
- `kubectl` (opcional, para verificar el clúster en local)
- Provider: `hashicorp/aws` ~> 5.x
- Rol **LabRole** disponible en la cuenta del lab (usado por EKS)

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

4. **Etapa 3 — EKS:**

```bash
cd ../etapa_3
terraform init
terraform apply
terraform output
```

5. Configura secrets en GitHub (tabla abajo) en **este repositorio**.
6. Push a la rama **`deploy`** → workflow `cd.yml` → build ECR → `kubectl apply` → rollout.

Verificar despliegue (opcional, en local):

```bash
aws eks update-kubeconfig --region us-east-1 --name innovatech-cluster
kubectl get nodes
kubectl get pods
kubectl get svc frontend    # EXTERNAL-IP = URL pública
```

**Destruir** (solo al cerrar el lab):

```bash
cd etapa_3 && terraform destroy
cd ../etapa_1 && terraform destroy
```

---

## 📦 ¿Qué despliega este proyecto?

| Etapa | Recursos |
|-------|----------|
| **etapa_1** | 3 repos ECR: `innovatech-frontend`, `innovatech-backend-ventas`, `innovatech-backend-despachos` |
| **etapa_3** | VPC, 2 subnets públicas, IGW, clúster EKS `innovatech-cluster`, node group `t3.medium` (1–3 nodos) |
| **k8s/** | Deployments (frontend, 2 backends, MySQL), Services, Secret, ConfigMap, HPA, metrics-server |

| Output (etapa_1) | Uso |
|--------|-----|
| `ecr_registry` | Prefijo de registro ECR (`ACCOUNT.dkr.ecr.REGION.amazonaws.com`) |
| `ecr_frontend` / `ecr_ventas` / `ecr_despachos` | URLs completas de cada repositorio |

| Output (etapa_3) | Uso |
|--------|-----|
| `cluster_name` | Nombre del clúster (`innovatech-cluster`) — coincide con `cd.yml` |
| `configure_kubectl` | Comando para conectar `kubectl` al clúster |

MySQL en producción corre como **pod en EKS** (`mysql:3306`), con bases `ventas_db` y `despachos_db`.

---

## 🧭 Diagrama de arquitectura

```
Internet
   │
   ▼
[ Service frontend — LoadBalancer :80 ]
   │
   ▼
[ Pod frontend — Nginx :8080 ]
   ├── proxy /api/v1/ventas   → backend-ventas:8080
   └── proxy /api/v1/despachos → backend-despachos:8081
              │
              ▼
[ Pods backend-ventas / backend-despachos ]  ← HPA (CPU 50%)
              │
              ▼
[ Pod MySQL — ClusterIP :3306 ]
```

```
GitHub (rama deploy) → Actions (cd.yml)
        ├── build + push → ECR (3 imágenes)
        ├── aws eks update-kubeconfig
        ├── kubectl apply -f k8s/
        └── kubectl set image + rollout status
```

---

## 📌 Mejores prácticas incluidas

- Infra en dos etapas: ECR independiente del ciclo de vida de EKS.
- Variables con defaults en `variables.tf`; valores sensibles fuera de Git.
- Manifiestos K8s versionados; imágenes actualizadas por tag `GITHUB_SHA` en el pipeline.
- **HPA** en ambos backends con **metrics-server** para escalado por CPU.
- Requests/limits de CPU y memoria en los deployments de backends.
- Pipeline centralizado: un solo workflow orquesta los 4 repos (infra + 3 apps).

### Secrets GitHub (solo en este repositorio — `DevopsEV2-infra`)

| Secret | Origen |
|--------|--------|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` | Learner Lab (renovar cada sesión) |

`AWS_REGION` (`us-east-1`) y `CLUSTER_NAME` (`innovatech-cluster`) están definidos en `cd.yml`.

> **Nota EV3:** el despliegue a EKS se dispara **solo desde este repo**. Los repos de apps (`frontend`, `ventas`, `despachos`) no tienen pipeline propio; este workflow hace checkout de los tres y orquesta build + deploy.

---

## 🔧 Cómo extender este proyecto

- Módulos Terraform (`modules/network`, `modules/eks`).
- Backend remoto (S3 + DynamoDB lock) — no disponible en todos los labs.
- RDS en lugar de MySQL en pod.
- Ingress Controller (ALB) en lugar de Service LoadBalancer.
- PersistentVolumeClaim para datos de MySQL.
- Liveness/readiness probes en los deployments.
- Variables por ambiente (`dev` / `prod` tfvars).
- La carpeta `etapa_2/` corresponde al EP2 (EC2); se mantiene como referencia histórica.
