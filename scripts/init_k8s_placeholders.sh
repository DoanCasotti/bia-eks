#!/bin/bash
# Substitui os placeholders dos manifests k8s com os outputs do Terraform.
# Executar UMA VEZ após o primeiro `terraform apply`, antes do Argo CD sincronizar.
# Uso: ./scripts/init_k8s_placeholders.sh

set -e

cd "$(dirname "$0")/../terraform"

echo "Lendo outputs do Terraform..."
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
ACM_ARN=$(terraform output -raw acm_arn)
SUBNET_A=$(terraform output -raw subnet_public_a)
SUBNET_B=$(terraform output -raw subnet_public_b)
ECR_URL=$(terraform output -raw ecr_repository_url)

K8S_DIR="../k8s"

echo "Substituindo placeholders em deployment.yaml..."
sed -i "s|IMAGE_PLACEHOLDER|${ECR_URL}:latest|" "$K8S_DIR/deployment.yaml"
sed -i "s|DB_HOST_PLACEHOLDER|${RDS_ENDPOINT}|" "$K8S_DIR/deployment.yaml"

echo "Substituindo placeholders em ingress.yaml..."
sed -i "s|ACM_ARN_PLACEHOLDER|${ACM_ARN}|" "$K8S_DIR/ingress.yaml"
sed -i "s|SUBNET_A_PLACEHOLDER|${SUBNET_A}|" "$K8S_DIR/ingress.yaml"
sed -i "s|SUBNET_B_PLACEHOLDER|${SUBNET_B}|" "$K8S_DIR/ingress.yaml"

echo ""
echo "Placeholders substituídos. Faça commit e push dos arquivos k8s/ para o repositório GitOps."
echo "O Argo CD vai detectar a mudança e aplicar automaticamente."
