# O hostname do ALB é provisionado pelo AWS Load Balancer Controller após o Argo CD aplicar o Ingress.
# Lemos o ALB via data source para não depender do ingress gerenciado pelo Terraform.
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
