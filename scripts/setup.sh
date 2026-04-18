#!/bin/bash
set -euo pipefail

echo "=== k8s-gitops-platform Setup ==="

# Check prerequisites
for cmd in docker k3d terraform kubectl helm; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not installed."
    echo ""
    echo "Install missing tools:"
    echo "  brew install k3d terraform kubectl helm"
    echo "  Docker Desktop: https://www.docker.com/products/docker-desktop/"
    exit 1
  fi
done

echo "All prerequisites found."
echo ""

# Step 1: Terraform
echo "=== Step 1: Provisioning cluster with Terraform ==="
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# Step 2: Verify cluster
echo ""
echo "=== Step 2: Verifying cluster ==="
kubectl cluster-info --context k3d-gitops-lab
kubectl get nodes

# Step 3: Wait for ArgoCD
echo ""
echo "=== Step 3: Waiting for ArgoCD to be ready ==="
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Step 4: Get ArgoCD admin password
echo ""
echo "=== Step 4: ArgoCD Access ==="
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD UI:   http://localhost:30080"
echo "Username:    admin"
echo "Password:    $ARGOCD_PASS"

# Step 5: Wait for Grafana
echo ""
echo "=== Step 5: Waiting for Grafana to be ready ==="
kubectl wait --for=condition=available deployment/kube-prometheus-stack-grafana -n monitoring --timeout=300s

echo ""
echo "=== Step 6: Grafana Access ==="
echo "Grafana UI:  http://localhost:30090"
echo "Username:    admin"
echo "Password:    admin"

# Step 6: Apply ArgoCD application
echo ""
echo "=== Step 7: Deploying sample app via ArgoCD ==="
kubectl apply -f argocd/apps/sample-app.yaml

echo ""
echo "=== Setup Complete ==="
echo "Your GitOps platform is running. Push changes to git and ArgoCD will sync automatically."
