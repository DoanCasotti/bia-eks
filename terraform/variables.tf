variable "aws_region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "bia-eks-cluster"
}

variable "db_name" {
  default = "biadb"
}

variable "db_user" {
  description = "Usuário do banco RDS. Passar via TF_VAR_db_user"
  sensitive   = true
}

variable "db_password" {
  description = "Senha do banco RDS. Passar via TF_VAR_db_password"
  sensitive   = true
}

variable "ecr_repo_name" {
  default = "bia"
}

variable "domain" {
  default = "projeto-aws.com.br"
}

variable "app_subdomain" {
  default = "bia-eks.projeto-aws.com.br"
}

variable "s3_state_bucket" {
  default = "bia-eks-terraform-state"
}
