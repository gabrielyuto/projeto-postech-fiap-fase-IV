resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  values = [
    yamlencode({
      global = {
        domain = "argocd.togglemaster.local"
      }

      server = {
        replicas = 2
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled = false
        }
      }

      repoServer = {
        replicas = 2
      }

      applicationSet = {
        replicas = 2
      }

      "redis-ha" = {
        enabled = false
      }

      configs = {
        params = {
          "server.insecure" = false
        }
      }
    })
  ]

  wait    = true
  timeout = 600

  depends_on = [module.eks]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = var.metrics_server_chart_version

  wait       = true
  timeout    = 600
  depends_on = [module.eks]
}

# Descriptografa no cluster os SealedSecrets versionados no Git (kubeseal).
resource "helm_release" "sealed_secrets" {
  name       = "sealed-secrets"
  namespace  = "kube-system"
  repository = "https://bitnami.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = var.sealed_secrets_chart_version

  values = [
    yamlencode({
      fullnameOverride = "sealed-secrets-controller"
    })
  ]

  wait       = true
  timeout    = 600
  depends_on = [module.eks]
}

resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = "traefik"
  create_namespace = true
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_chart_version

  values = [
    yamlencode({
      deployment = {
        replicas = 2
      }

      ingressClass = {
        enabled        = true
        isDefaultClass = false
        name           = "traefik"
      }

      providers = {
        kubernetesIngress = {
          ingressClass         = "traefik"
          strictPrefixMatching = true
          publishedService     = { enabled = true }
        }
      }

      service = {
        type = "LoadBalancer"
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type"    = "nlb"
          "service.beta.kubernetes.io/aws-load-balancer-subnets" = join(",", module.vpc.public_subnet_ids)
        }
      }
    })
  ]

  wait       = true
  timeout    = 900
  depends_on = [module.eks]
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "93.6.0"

  values = [
    yamlencode({
      grafana = {
        enabled = true
      }

      alertmanager = {
        enabled = true
      }

      prometheus = {
        prometheusSpec = {
          retention = "7d"
        }
      }
    })
  ]

  wait       = true
  timeout    = 900
  depends_on = [module.eks]
}