Excelente iniciativa. Transformar manifests soltos em infraestrutura como código (IaC) sólida e reaproveitável é exatamente o caminho para escalar projetos de DevOps e nuvem.

Como você vai traduzir essa estrutura do seu colega para Terraform, estruturei o arquivo .md não apenas como um repositório dos YAMLs, mas mapeando o que cada peça representa na sua futura stack da AWS (EKS, RDS, ECR, ALB) e quais resources do provider do Kubernetes no Terraform você precisará usar.

Você pode copiar o conteúdo abaixo e salvar como arquitetura_referencia.md na sua máquina:

Markdown
# Arquitetura de Referência: EKS + GitOps (Argo CD) - Projeto Bia

Este documento mapeia a infraestrutura e os manifests Kubernetes da aplicação "Bia", servindo como base para a recriação do ambiente utilizando Terraform.

## 1. Visão Geral da Infraestrutura AWS (Pré-requisitos K8s)

Antes de aplicar os manifests do Kubernetes via Terraform (usando os providers `kubernetes` e `helm`), a infraestrutura base da AWS precisa estar provisionada.

* **Cluster K8s:** Amazon EKS.
* **Banco de Dados:** Amazon RDS (PostgreSQL).
    * *Ref:* `db-bia-eks.cs9w2owgmo8f.us-east-1.rds.amazonaws.com:5432`
* **Registry de Imagens:** Amazon ECR.
    * *Ref:* `976808777516.dkr.ecr.us-east-1.amazonaws.com/bia`
* **Rede/Borda:** AWS Application Load Balancer (ALB) gerenciado via AWS Load Balancer Controller no EKS.

---

## 2. Tradução para Terraform: Recursos Kubernetes

Abaixo estão os manifests originais do projeto, agrupados por sua função, com a indicação de como devem ser implementados no Terraform.

### 2.1. O "Cérebro" GitOps (Argo CD Application)

* **Objetivo:** Conectar o repositório Git ao cluster K8s, ativando sincronização automática e `selfHeal`.
* **No Terraform:** Como `Application` é um Custom Resource Definition (CRD) do Argo CD, você precisará usar o resource `kubernetes_manifest` do Terraform.

```yaml
# Manifest Original: Argo CD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bia-k8s
  namespace: argocd
spec:
  project: default
  source:
    repoURL: [https://github.com/alisrios/bia-k8s-gitops](https://github.com/alisrios/bia-k8s-gitops)
    path: k8s/.
    targetRevision: HEAD
  destination:
    server: [https://kubernetes.default.svc](https://kubernetes.default.svc)
    namespace: default
  syncPolicy:
    automated:
      selfHeal: true
2.2. A Aplicação Principal (Deployment)
Objetivo: Gerenciar as réplicas (Pods) da aplicação e definir a estratégia de atualização (RollingUpdate).

No Terraform: Utilizar o resource kubernetes_deployment_v1.

Atenção de Segurança: As variáveis de ambiente DB_USER e DB_PWD estão expostas no YAML original. Na sua versão em Terraform, é altamente recomendável migrar essas credenciais para o AWS Secrets Manager ou kubernetes_secret e referenciá-las via valueFrom.

YAML
# Manifest Original: Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bia
  namespace: default
  labels:
    app: bia
spec:
  replicas: 2
  selector:
    matchLabels:
      app: bia
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
  template:
    metadata:
      labels:
        app: bia
    spec:
      containers:
        - name: bia
          image: [976808777516.dkr.ecr.us-east-1.amazonaws.com/bia:da60aafc6e615652351b09061518e8e9aa0d2921](https://976808777516.dkr.ecr.us-east-1.amazonaws.com/bia:da60aafc6e615652351b09061518e8e9aa0d2921)
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
              protocol: TCP
          env:
            - name: DB_USER
              value: postgres
            - name: DB_PWD
              value: postgres
            - name: DB_HOST
              value: db-bia-eks.cs9w2owgmo8f.us-east-1.rds.amazonaws.com
            - name: DB_PORT
              value: '5432'
2.3. O Ponto de Acesso Interno (Service)
Objetivo: Criar um balanceador de carga interno estático para os Pods.

No Terraform: Utilizar o resource kubernetes_service_v1.

Configuração: Tipo NodePort mapeando a porta do container (8080) para a porta exposta nos nós do EKS.

YAML
# Manifest Original: Service
apiVersion: v1
kind: Service
metadata:
  name: bia
  namespace: default
spec:
  type: NodePort
  selector:
    app: bia
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
2.4. A Exposição Externa na Nuvem (Ingress com AWS ALB)
Objetivo: Expor a aplicação para a internet de forma segura via HTTPS, roteando o tráfego do AWS ALB para as instâncias do EKS.

No Terraform: Utilizar o resource kubernetes_ingress_v1.

Destaques Estruturais:

A anotação alb.ingress.kubernetes.io/group.name: bia-alb é crucial para compartilhar o mesmo Load Balancer físico da AWS entre várias aplicações (como a interface do próprio Argo CD e a aplicação Bia), otimizando custos.

Certificado ACM referenciado na anotação para terminação SSL.

Tipo de target configurado como instance (roteia para os Nodes, que repassam para o NodePort do Service).

YAML
# Manifest Original: Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bia-ingress
  namespace: default
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: instance
    alb.ingress.kubernetes.io/group.name: bia-alb
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:976808777516:certificate/a5368b26-d5e7-4606-93bb-b7d764c5575c
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-2016-08
    alb.ingress.kubernetes.io/target-group-attributes: deregistration_delay.timeout_seconds=30
    alb.ingress.kubernetes.io/subnets: subnet-06006850eabb7dba0,subnet-017091556fa6401ef
spec:
  ingressClassName: alb
  rules:
    - host: bia-eks.alisriosti.com.br
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: bia
                port:
                  number: 8080

Se precisar de ajuda para escrever os módulos `.tf` específicos para converter qualquer uma dessas peças (especialmente a parte das *annotations* do Ingress, que no Terraform usam uma sintaxe específica de mapa), é só avisar. Como você planeja estruturar o Terraform? Vai colocar a infra (EKS, RDS) e os deploys do Kubernetes no mesmo state ou em pipelines separados?