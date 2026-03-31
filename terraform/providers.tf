terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "doan-gui"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.bia.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.bia.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.bia.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.bia.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.bia.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.bia.token
  }
}
