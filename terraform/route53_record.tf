# ATENÇÃO: Este recurso depende do ALB já existir no cluster.
# O ALB é criado pelo AWS Load Balancer Controller APÓS o Argo CD aplicar o Ingress.
#
# Ordem correta de execução:
#   1. terraform apply (provisiona EKS, RDS, ECR, Argo CD)
#   2. ./scripts/init_k8s_placeholders.sh  (substitui placeholders e faz push para o GitOps)
#   3. Aguardar o Argo CD sincronizar e o ALB ser provisionado (~2-3 min)
#   4. terraform apply  (agora o data "aws_lb" resolve e o record Route53 é criado)
#
# O hostname do ALB é provisionado pelo AWS Load Balancer Controller após o Argo CD aplicar o Ingress.
data "aws_lb" "bia" {
  tags = {
    "ingress.k8s.aws/stack" = "bia-alb"
  }
}

resource "aws_route53_record" "bia" {
  zone_id = data.aws_route53_zone.bia.zone_id
  name    = var.app_subdomain
  type    = "CNAME"
  ttl     = 300

  records = [data.aws_lb.bia.dns_name]
}
