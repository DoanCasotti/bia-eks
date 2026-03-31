resource "kubernetes_ingress_v1" "bia" {
  metadata {
    name      = "bia-ingress"
    namespace = "default"

    annotations = {
      "alb.ingress.kubernetes.io/scheme"                         = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"                    = "instance"
      "alb.ingress.kubernetes.io/group.name"                     = "bia-alb"
      "alb.ingress.kubernetes.io/listen-ports"                   = "[{\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/certificate-arn"                = data.aws_acm_certificate.bia.arn
      "alb.ingress.kubernetes.io/ssl-policy"                     = "ELBSecurityPolicy-2016-08"
      "alb.ingress.kubernetes.io/target-group-attributes"        = "deregistration_delay.timeout_seconds=30"
      "alb.ingress.kubernetes.io/subnets"                        = "${aws_subnet.public_a.id},${aws_subnet.public_b.id}"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.app_subdomain

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.bia.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_v1.bia,
    helm_release.alb_controller,
  ]
}
