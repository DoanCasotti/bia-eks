resource "kubernetes_deployment_v1" "bia" {
  metadata {
    name      = "bia"
    namespace = "default"
    labels    = { app = "bia" }
  }

  spec {
    replicas = 2

    selector {
      match_labels = { app = "bia" }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        labels = { app = "bia" }
      }

      spec {
        container {
          name              = "bia"
          image             = "${aws_ecr_repository.bia.repository_url}:latest"
          image_pull_policy = "Always"

          port {
            container_port = 8080
            protocol       = "TCP"
          }

          env {
            name = "DB_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.bia_db.metadata[0].name
                key  = "DB_USER"
              }
            }
          }

          env {
            name = "DB_PWD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.bia_db.metadata[0].name
                key  = "DB_PWD"
              }
            }
          }

          env {
            name  = "DB_HOST"
            value = aws_db_instance.bia.address
          }

          env {
            name  = "DB_PORT"
            value = "5432"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret.bia_db,
    aws_eks_node_group.bia,
  ]
}
