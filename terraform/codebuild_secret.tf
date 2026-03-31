# Secret do GitHub token para o CodeBuild atualizar o repositório GitOps
resource "aws_secretsmanager_secret" "github_token" {
  name        = "github/token"
  description = "GitHub token usado pelo CodeBuild para atualizar k8s/deployment.yaml no bia-eks"
}

resource "aws_secretsmanager_secret_version" "github_token" {
  secret_id     = aws_secretsmanager_secret.github_token.id
  secret_string = var.github_token
}

# Policy para o CodeBuild ler o secret
resource "aws_iam_policy" "codebuild_secrets" {
  name = "bia-codebuild-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = aws_secretsmanager_secret.github_token.arn
    }]
  })
}
