output "rds_endpoint" {
  description = "DB_HOST_PLACEHOLDER → deployment.yaml"
  value       = aws_db_instance.bia.address
}

output "subnet_public_a" {
  description = "SUBNET_A_PLACEHOLDER → ingress.yaml"
  value       = aws_subnet.public_a.id
}

output "subnet_public_b" {
  description = "SUBNET_B_PLACEHOLDER → ingress.yaml"
  value       = aws_subnet.public_b.id
}

output "ecr_repository_url" {
  description = "Base para IMAGE_PLACEHOLDER → deployment.yaml (adicionar :<tag> do commit)"
  value       = aws_ecr_repository.bia.repository_url
}

output "alb_dns" {
  description = "DNS do ALB para acesso direto via HTTP"
  value       = "Disponível após o Argo CD aplicar o Ingress. Rode: aws elbv2 describe-load-balancers --profile doan-awsfree --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-bia`)].DNSName' --output text"
}
