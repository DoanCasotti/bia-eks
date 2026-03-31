resource "kubernetes_secret" "bia_db" {
  metadata {
    name      = "bia-db-secret"
    namespace = "default"
  }

  data = {
    DB_USER = var.db_user
    DB_PWD  = var.db_password
  }

  depends_on = [aws_eks_node_group.bia]
}
