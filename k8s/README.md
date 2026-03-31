# k8s/ — Manifests GitOps (gerenciados pelo Argo CD)

Estes manifests são aplicados automaticamente pelo Argo CD no cluster EKS.
**Não aplicar manualmente com `kubectl apply`** — o Argo CD é o único responsável.

## Placeholders que precisam ser substituídos antes do primeiro deploy

| Placeholder | Onde substituir | Valor |
|---|---|---|
| `IMAGE_PLACEHOLDER` | `deployment.yaml` | URL do ECR + tag do commit (ex: `123456789.dkr.ecr.us-east-1.amazonaws.com/bia:abc1234`) |
| `DB_HOST_PLACEHOLDER` | `deployment.yaml` | Endpoint do RDS gerado pelo Terraform (output `aws_db_instance.bia.address`) |
| `ACM_ARN_PLACEHOLDER` | `ingress.yaml` | ARN do certificado ACM (output do `data.aws_acm_certificate.bia.arn`) |
| `SUBNET_A_PLACEHOLDER` | `ingress.yaml` | ID da subnet pública A (output do `aws_subnet.public_a.id`) |
| `SUBNET_B_PLACEHOLDER` | `ingress.yaml` | ID da subnet pública B (output do `aws_subnet.public_b.id`) |

## Segredos

O `bia-db-secret` (DB_USER e DB_PWD) é criado pelo Terraform via `secret.tf`.
Não adicionar credenciais nestes arquivos YAML.

## Pipeline de atualização de imagem

O `buildspec.yml` faz o push da imagem para o ECR.
Após o push, atualizar `IMAGE_PLACEHOLDER` no `deployment.yaml` com a nova tag
para que o Argo CD detecte a mudança e faça o rollout.
