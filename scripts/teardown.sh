#!/bin/bash
set -euo pipefail

echo "=== Tearing down k8s-gitops-platform ==="

cd terraform
terraform destroy -auto-approve
cd ..

echo "=== Teardown complete ==="
