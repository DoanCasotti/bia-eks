# ATENÇÃO: O Ingress da aplicação BIA é gerenciado exclusivamente pelo Argo CD via GitOps.
# Repositório GitOps: https://github.com/DoanCasotti/bia-eks (path: k8s/.)
#
# O Terraform NÃO deve criar o Ingress para evitar conflito de reconciliação com o Argo CD.
# O hostname do ALB é gerado pelo AWS Load Balancer Controller após o Argo CD aplicar o Ingress.
