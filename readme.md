# BIA no EKS — Terraform + GitOps (Argo CD)

Projeto de estudo da aplicação **BIA** (Node.js + PostgreSQL, da Formação AWS) em **Amazon EKS**. O repositório reúne definições **Terraform** para a infraestrutura e configuração de **GitOps com Argo CD**.

Minha contribuição está na tradução dos manifests de referência para Terraform e na organização da infraestrutura EKS/GitOps. Este repositório é um laboratório, com valores de ambiente que precisam ser adaptados antes de uma implantação.

## Arquitetura

```
                ┌────────────── VPC (vpc.tf) ───────────────┐
 Route 53 ──►   │  ALB (AWS Load Balancer Controller)       │
 (route53_      │        │ ingress.tf                       │
  record.tf)    │        ▼                                  │
                │  EKS (eks.tf + eks_addons.tf)             │
                │   └─ Deployment/Service da BIA            │
                │        │ imagem ▲ ECR (ecr.tf)            │
                │        ▼                                  │
                │  RDS PostgreSQL (rds.tf)                  │
                │   └─ credenciais no Secrets Manager       │
                └───────────────────────────────────────────┘
 Argo CD (argocd_app.tf) observa o repositório e sincroniza os manifests
```

## O que está em Terraform (`terraform/`)

| Arquivo | Recurso |
|---|---|
| `vpc.tf` | VPC, subnets públicas e privadas |
| `eks.tf`, `eks_addons.tf` | Cluster EKS e add-ons |
| `alb_controller_policy.json`, `ingress.tf` | AWS Load Balancer Controller e Ingress |
| `ecr.tf` | Repositório de imagens |
| `rds.tf`, `secret.tf` | PostgreSQL no RDS, com a senha no Secrets Manager (`var.db_password`) |
| `codebuild_secret.tf` | Segredo para o pipeline de build |
| `deployment.tf`, `service.tf` | Workload da BIA via provider Kubernetes |
| `argocd_app.tf` | Aplicação Argo CD (GitOps) |
| `route53_record.tf` | DNS da aplicação |
| `backend.tf` | Estado remoto do Terraform |

Os manifests equivalentes em YAML estão em `k8s/` (referência) e o plano de migração YAML → Terraform está em [`plano_terraform.md`](plano_terraform.md).

## Preparar o ambiente

Requisitos: AWS CLI autenticada, Terraform e permissões AWS compatíveis com os recursos. Revise região, domínio, estado remoto e valores específicos da conta nos arquivos antes de executar. Provisionar os recursos gera cobrança na AWS.

```bash
cd terraform
cp .env.example .env      # preencha com seus valores (não versionar)
source .env              # exporta AWS_PROFILE e TF_VAR_* no shell atual
terraform init
terraform validate
```

**A implantação exige etapas.** O recurso `kubernetes_manifest.argocd_app_bia` depende do cluster EKS existente e do Argo CD instalado. Leia `terraform/argocd_app.tf` e `plano_terraform.md` antes de planejar a aplicação; os comandos acima não constituem um deploy completo. Revise o plano e as dependências dos providers Kubernetes/Helm antes de executar um `apply`.

Use `TF_VAR_db_user`, `TF_VAR_db_password` e `TF_VAR_github_token` para os valores locais. Não versione `.env`, arquivos de plano ou estado com dados sensíveis. Revise também `terraform.tfvars`, pois valores nesse arquivo podem prevalecer sobre variáveis de ambiente.

**Limite desta documentação:** a estrutura e os arquivos foram revisados; uma implantação AWS não foi executada como parte da revisão do README.

## O que eu aprendi / decisões
- Senha do banco fora do código: Secrets Manager + variável sensível
- GitOps: o cluster converge para o que está no Git, sem `kubectl apply` manual
- ALB Controller em vez de um Service `LoadBalancer` por aplicação

## Créditos
A aplicação BIA é do curso **Formação AWS** ([henrylle/bia](https://github.com/henrylle/bia)). Os manifests Kubernetes de referência (`k8s/`) partiram do trabalho de um colega. A tradução para Terraform e a infraestrutura EKS/GitOps são minhas.
