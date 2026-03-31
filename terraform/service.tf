resource "kubernetes_service_v1" "bia" {
  metadata {
    name      = "bia"
    namespace = "default"
  }

  spec {
    type     = "NodePort"
    selector = { app = "bia" }

    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_deployment_v1.bia]
}
