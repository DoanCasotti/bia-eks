# ATENÇÃO: O Service da aplicação BIA é gerenciado exclusivamente pelo Argo CD via GitOps.
# Repositório GitOps: https://github.com/DoanCasotti/bia-eks (path: k8s/.)
#
# O Terraform NÃO deve criar o Service para evitar conflito de reconciliação com o Argo CD.
