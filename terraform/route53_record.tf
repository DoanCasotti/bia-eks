resource "aws_route53_record" "bia" {
  zone_id = data.aws_route53_zone.bia.zone_id
  name    = var.app_subdomain
  type    = "CNAME"
  ttl     = 300

  records = [kubernetes_ingress_v1.bia.status[0].load_balancer[0].ingress[0].hostname]

  depends_on = [kubernetes_ingress_v1.bia]
}
