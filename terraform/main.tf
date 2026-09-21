terraform {
  required_version = ">= 1.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# --- k3d Cluster ---

resource "null_resource" "k3d_cluster" {
  provisioner "local-exec" {
    command = <<-EOT
      k3d cluster create ${var.cluster_name} \
        --servers ${var.server_count} \
        --agents ${var.agent_count} \
        --port "${var.ingress_http_port}:80@loadbalancer" \
        --port "${var.ingress_https_port}:443@loadbalancer" \
        --k3s-arg "--disable=traefik@server:0" \
        --wait
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete ${self.triggers.cluster_name}"
  }

  triggers = {
    cluster_name = var.cluster_name
  }
}

# --- Configure K8s and Helm providers after cluster creation ---

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3d-${var.cluster_name}"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "k3d-${var.cluster_name}"
  }
}

# --- Namespaces ---

resource "kubernetes_namespace" "argocd" {
  depends_on = [null_resource.k3d_cluster]

  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "monitoring" {
  depends_on = [null_resource.k3d_cluster]

  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "apps" {
  depends_on = [null_resource.k3d_cluster]

  metadata {
    name = "apps"
  }
}

# --- ArgoCD ---

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.55.0"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  set {
    name  = "server.service.nodePortHttp"
    value = var.argocd_nodeport
  }
}

# --- Monitoring Stack (Prometheus + Grafana) ---

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "56.6.2"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "grafana.service.type"
    value = "NodePort"
  }

  set {
    name  = "grafana.service.nodePort"
    value = var.grafana_nodeport
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }
}
