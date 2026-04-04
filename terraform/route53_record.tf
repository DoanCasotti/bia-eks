# Route53 gerenciado manualmente na conta externa.
#
# Após o deploy, pegue o DNS do ALB no output "alb_dns" e adicione
# manualmente na Hosted Zone da outra conta:
#
#   Tipo : CNAME
#   Nome : bia-eks.projeto-aws.com.br
#   Valor: <alb_dns output>
