output "cluster_name" {
  value = var.cluster_name
}

output "argocd_url" {
  value = "http://localhost:${var.argocd_nodeport}"
}

output "grafana_url" {
  value = "http://localhost:${var.grafana_nodeport}"
}

output "kubeconfig_context" {
  value = "k3d-${var.cluster_name}"
}
