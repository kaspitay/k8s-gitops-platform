variable "cluster_name" {
  description = "Name of the k3d cluster"
  type        = string
  default     = "gitops-lab"
}

variable "server_count" {
  description = "Number of server (control plane) nodes"
  type        = number
  default     = 1
}

variable "agent_count" {
  description = "Number of agent (worker) nodes"
  type        = number
  default     = 2
}

variable "ingress_http_port" {
  description = "Host port mapped to ingress HTTP"
  type        = number
  default     = 8080
}

variable "ingress_https_port" {
  description = "Host port mapped to ingress HTTPS"
  type        = number
  default     = 8443
}

variable "argocd_nodeport" {
  description = "NodePort for ArgoCD server"
  type        = string
  default     = "30080"
}

variable "grafana_nodeport" {
  description = "NodePort for Grafana"
  type        = number
  default     = 30090
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "admin"
  sensitive   = true
}
