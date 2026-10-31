# Run this Terraform root only AFTER the EKS cluster and EBS CSI add-on are ready.
# Example: cd addons && terraform init && terraform plan && terraform apply

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 900
  wait             = true

  values = [yamlencode({
    prometheus = {
      prometheusSpec = {
        retention = "7d"
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "gp3"
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = { storage = "20Gi" }
              }
            }
          }
        }
      }
    }
    grafana = {
      persistence = {
        enabled          = true
        type             = "pvc"
        storageClassName = "gp3"
        accessModes      = ["ReadWriteOnce"]
        size             = "5Gi"
      }
      service = {
        type = "ClusterIP"
      }
    }
    alertmanager = {
      alertmanagerSpec = {
        storage = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "gp3"
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = { storage = "5Gi" }
              }
            }
          }
        }
      }
    }
  })]
}

# Expose Grafana through an AWS Network Load Balancer.
resource "kubernetes_service_v1" "grafana_lb" {
  metadata {
    name      = "grafana-public"
    namespace = "monitoring"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"   = "external"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
    }
  }

  spec {
    type = "LoadBalancer"
    selector = {
      "app.kubernetes.io/name" = "grafana"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 900
  wait             = true

  values = [yamlencode({
    server = {
      extraArgs = ["--insecure"]
      service = {
        type = "ClusterIP"
      }
    }
  })]
}

resource "kubernetes_service_v1" "argocd_lb" {
  metadata {
    name      = "argocd-public"
    namespace = "argocd"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"   = "external"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
    }
  }

  spec {
    type = "LoadBalancer"
    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }

  depends_on = [helm_release.argocd]
}
