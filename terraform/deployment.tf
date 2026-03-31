# ATENÇÃO: O Deployment da aplicação BIA é gerenciado exclusivamente pelo Argo CD via GitOps.
# Repositório GitOps: https://github.com/DoanCasotti/bia-eks (path: k8s/.)
#
# O Terraform NÃO deve criar o Deployment para evitar conflito de reconciliação com o Argo CD.
# O resource kubernetes_deployment_v1 foi removido intencionalmente deste arquivo.
#
# Para alterar réplicas, imagem ou variáveis de ambiente, edite os manifests no repositório GitOps.
