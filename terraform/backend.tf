terraform {
  backend "s3" {
    bucket  = "bia-eks-terraform-state"
    key     = "bia-eks/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
