resource "kubernetes_manifest" "argocd_app_bia" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "bia-k8s"
      namespace = "argocd"
    }

    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/DoanCasotti/bia-eks"
        path           = "k8s/."
        targetRevision = "HEAD"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }

      syncPolicy = {
        automated = {
          selfHeal = true
        }
      }
    }
  }

  depends_on = [helm_release.argocd]
}
