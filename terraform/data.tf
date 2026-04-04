# Leitura do cluster EKS após criação
data "aws_eks_cluster" "bia" {
  name = aws_eks_cluster.bia.name

  depends_on = [aws_eks_cluster.bia]
}

data "aws_eks_cluster_auth" "bia" {
  name = aws_eks_cluster.bia.name

  depends_on = [aws_eks_cluster.bia]
}

# Certificado ACM existente na conta (somente leitura)
data "aws_acm_certificate" "bia" {
  domain      = var.domain
  statuses    = ["ISSUED"]
  most_recent = true
}
