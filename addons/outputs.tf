output "grafana_load_balancer_hostname" {
  description = "Hostname for the Grafana Network Load Balancer"
  value       = try(kubernetes_service_v1.grafana_lb.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "argocd_load_balancer_hostname" {
  description = "Hostname for the Argo CD Network Load Balancer"
  value       = try(kubernetes_service_v1.argocd_lb.status[0].load_balancer[0].ingress[0].hostname, null)
}
