# Addons nativos do EKS
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.bia.name
  addon_name   = "coredns"

  depends_on = [aws_eks_node_group.bia]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.bia.name
  addon_name   = "kube-proxy"

  depends_on = [aws_eks_node_group.bia]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.bia.name
  addon_name   = "vpc-cni"

  depends_on = [aws_eks_node_group.bia]
}

# OIDC provider para IRSA (IAM Roles for Service Accounts)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.bia.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.bia.identity[0].oidc[0].issuer
}

# IAM Role para o AWS Load Balancer Controller via IRSA
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "alb_controller" {
  name = "bia-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "aws_iam_policy" "alb_controller" {
  name   = "bia-alb-controller-policy"
  policy = file("${path.module}/alb_controller_policy.json")
}

# Helm: AWS Load Balancer Controller
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller.arn
  }

  depends_on = [
    aws_eks_node_group.bia,
    aws_iam_role_policy_attachment.alb_controller,
  ]
}

# Helm: Argo CD
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "6.7.3"

  depends_on = [aws_eks_node_group.bia]
}
