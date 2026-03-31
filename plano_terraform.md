# Plano Terraform — Projeto Bia EKS

## Premissas

- Conta AWS já possui recursos existentes (EC2, Route53 Hosted Zone, certificado ACM) que **não serão alterados**
- O certificado ACM existente será referenciado via `data source` (somente leitura)
- A Hosted Zone do domínio `projeto-aws.com.br` será referenciada via `data source` (somente leitura)
- Toda a infraestrutura do Projeto Bia (VPC, EKS, RDS, ECR) será criada do zero, em recursos novos e isolados
- State remoto no S3 com criptografia, sem DynamoDB
- Profile AWS: `doan-gui`
- Região: `us-east-1`

---

## Estrutura de Arquivos

```
terraform/
├── backend.tf
├── providers.tf
├── variables.tf
├── terraform.tfvars
├── data.tf
│
├── vpc.tf
├── ecr.tf
├── rds.tf
├── eks.tf
├── eks_addons.tf
│
├── secret.tf
├── deployment.tf
├── service.tf
├── ingress.tf
├── argocd_app.tf
│
└── route53_record.tf
```

---

## Descrição de Cada Arquivo

### `backend.tf`
- Configura o remote state no S3
- `bucket`: variável a definir (ex: `bia-terraform-state-doan`)
- `key`: `bia-eks/terraform.tfstate`
- `region`: `us-east-1`
- `encrypt = true`
- Sem `dynamodb_table` (DynamoDB será descontinuado)

---

### `providers.tf`
- Provider `aws` com `profile = "doan-gui"` e `region = "us-east-1"`
- Provider `kubernetes` autenticado via `data` do EKS (token dinâmico, sem credenciais fixas)
- Provider `helm` para instalação do AWS Load Balancer Controller
- Versões fixadas para garantir reprodutibilidade

---

### `variables.tf` + `terraform.tfvars`
Variáveis configuráveis:

| Variável | Descrição |
|---|---|
| `aws_region` | Região AWS (default: us-east-1) |
| `cluster_name` | Nome do cluster EKS |
| `db_name` | Nome do banco de dados |
| `db_user` | Usuário do banco |
| `db_password` | Senha do banco (**sem default, passar via TF_VAR**) |
| `ecr_repo_name` | Nome do repositório ECR |
| `s3_state_bucket` | Nome do bucket S3 para o state |
| `domain` | Domínio base (projeto-aws.com.br) |
| `app_subdomain` | Subdomínio da app (bia-eks.projeto-aws.com.br) |

---

### `data.tf`
Leitura de recursos **já existentes** na conta (somente leitura, nada é alterado):

- `data "aws_acm_certificate"` — busca o certificado ACM existente para `*.projeto-aws.com.br` ou `projeto-aws.com.br`
- `data "aws_route53_zone"` — lê a Hosted Zone existente do domínio `projeto-aws.com.br`
- `data "aws_eks_cluster"` — lê o cluster após criação (usado pelos providers kubernetes/helm)
- `data "aws_eks_cluster_auth"` — token de autenticação do EKS

---

### `vpc.tf`
Cria uma VPC **nova e isolada** exclusiva para o Projeto Bia:

- VPC: `10.0.0.0/16`
- 2 subnets públicas (para o ALB) em AZs diferentes
- 2 subnets privadas (para os nodes EKS e RDS) em AZs diferentes
- Internet Gateway
- NAT Gateway (1 instância para reduzir custo)
- Route tables para subnets públicas e privadas
- Tags obrigatórias para o AWS Load Balancer Controller reconhecer as subnets:
  - Subnets públicas: `kubernetes.io/role/elb = 1`
  - Subnets privadas: `kubernetes.io/role/internal-elb = 1`
  - Todas: `kubernetes.io/cluster/<cluster_name> = shared`

---

### `ecr.tf`
Cria o repositório ECR para as imagens da aplicação Bia:

- `aws_ecr_repository` com nome `bia`
- `image_tag_mutability = "MUTABLE"` (permite sobrescrever tags)
- `scan_on_push = true` (boas práticas de segurança)
- Lifecycle policy para manter apenas as últimas 10 imagens não tagueadas

---

### `rds.tf`
Cria o banco de dados PostgreSQL:

- `aws_db_instance` com engine `postgres`
- Instância: `db.t3.micro` (ajustável)
- Armazenamento: 20GB gp2
- Multi-AZ: `false` (pode ser habilitado para produção real)
- Subnet group usando as subnets privadas da nova VPC
- Security group permitindo acesso apenas dos nodes EKS (porta 5432)
- `skip_final_snapshot = false` — snapshot final obrigatório antes de destruir
- `deletion_protection = true` — proteção contra destruição acidental
- Credenciais via variáveis (`db_user`, `db_password`)

---

### `eks.tf`
Cria o cluster EKS:

- `aws_eks_cluster` na nova VPC, subnets privadas
- Versão Kubernetes: `1.29`
- IAM Role para o control plane
- Node Group gerenciado (`aws_eks_node_group`):
  - Tipo: `t3.medium`
  - Min: 1 / Desired: 2 / Max: 3
  - IAM Role para os nodes com policies: `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`

---

### `eks_addons.tf`
Instala componentes essenciais no EKS via Helm:

- **AWS Load Balancer Controller** — necessário para o Ingress ALB funcionar
  - Instalado via `helm_release` no namespace `kube-system`
  - IAM Role com IRSA (IAM Roles for Service Accounts)
- **CoreDNS, kube-proxy, vpc-cni** — addons nativos do EKS via `aws_eks_addon`

---

### `secret.tf`
Cria o Kubernetes Secret com as credenciais do banco:

- `kubernetes_secret` no namespace `default`
- Chaves: `DB_USER` e `DB_PWD`
- Valores vindos das variáveis Terraform (nunca hardcoded)
- Resolve o problema de segurança do YAML original que expunha as credenciais em texto puro

---

### `deployment.tf`
Cria o Deployment da aplicação Bia:

- `kubernetes_deployment_v1` com 2 réplicas
- Estratégia `RollingUpdate` (maxSurge: 25%, maxUnavailable: 25%)
- Imagem do ECR criado neste projeto
- Variáveis de ambiente:
  - `DB_USER` e `DB_PWD` via `valueFrom.secretKeyRef` (referenciando o `secret.tf`)
  - `DB_HOST` apontando para o endpoint do RDS criado
  - `DB_PORT`: 5432
- `imagePullPolicy: Always`

---

### `service.tf`
Cria o Service Kubernetes:

- `kubernetes_service_v1` tipo `NodePort`
- Porta 8080 → targetPort 8080
- Selector: `app = bia`

---

### `ingress.tf`
Cria o Ingress com AWS ALB:

- `kubernetes_ingress_v1` com `ingressClassName: alb`
- Annotations:
  - `scheme: internet-facing`
  - `target-type: instance`
  - `group.name: bia-alb` (compartilha ALB com Argo CD, otimiza custo)
  - `listen-ports: HTTPS 443`
  - `certificate-arn`: ARN do certificado ACM existente (via `data source`)
  - `ssl-policy: ELBSecurityPolicy-2016-08`
  - `subnets`: subnets públicas criadas na nova VPC
- Host: `bia-eks.projeto-aws.com.br`
- Backend: service `bia` porta 8080

---

### `argocd_app.tf`
Cria o Argo CD Application (CRD):

- `kubernetes_manifest` para o resource `Application` do Argo CD
- Namespace: `argocd`
- Repo: `https://github.com/alisrios/bia-k8s-gitops`
- Path: `k8s/.`
- `selfHeal: true` + `automated sync`
- **Pré-requisito:** Argo CD precisa estar instalado no cluster antes do `terraform apply` deste resource (pode ser instalado via Helm no `eks_addons.tf`)

---

### `route53_record.tf`
Cria o registro DNS para a aplicação:

- `aws_route53_record` do tipo `CNAME` ou `A` (alias)
- Nome: `bia-eks.projeto-aws.com.br`
- Aponta para o DNS do ALB criado pelo Ingress
- Usa a Hosted Zone existente via `data source` (não cria nova zone, não altera registros existentes)

---

## Ordem de Execução (dependências)

```
1. backend.tf / providers.tf / variables.tf
2. vpc.tf
3. ecr.tf
4. rds.tf
5. eks.tf
6. eks_addons.tf  (depende do EKS estar pronto)
7. secret.tf      (depende do EKS)
8. deployment.tf  (depende do secret + ECR)
9. service.tf     (depende do deployment)
10. ingress.tf    (depende do service + ALB Controller)
11. argocd_app.tf (depende do Argo CD instalado)
12. route53_record.tf (depende do ALB criado pelo ingress)
```

O Terraform resolve as dependências automaticamente via `depends_on` e referências entre resources.

---

## O que NÃO será alterado na conta

| Recurso existente | Ação |
|---|---|
| EC2 existente | Nenhuma — não referenciado |
| Hosted Zone Route53 | Somente leitura via `data source` |
| Certificado ACM existente | Somente leitura via `data source` |
| Registros DNS existentes | Nenhuma — apenas novo registro será criado |
| VPC existente | Nenhuma — nova VPC será criada |

---

## Próximos Passos

Antes de gerar os arquivos `.tf`, confirme:

1. Nome do bucket S3 para o state (ou posso sugerir um)
2. Nome desejado para o cluster EKS
3. A senha do banco será passada via `TF_VAR_db_password` — confirma?
