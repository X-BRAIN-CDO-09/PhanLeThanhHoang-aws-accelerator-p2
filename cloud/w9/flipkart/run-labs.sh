#!/bin/bash
set -euo pipefail

#======================================================================
# GitOps Lab — Flipkart MERN: Setup & Deploy
# Chạy từ thư mục: cloud/w9/flipkart-mern/
# Yêu cầu: docker, minikube, kubectl đã cài sẵn
#======================================================================

PROFILE="w9"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Màu output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

banner() {
  echo ""
  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}  $1${NC}"
  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo ""
}

info() { echo -e "${GREEN}[INFO]${NC} $1"; }

#======================================================================
banner "1/4 — Khởi tạo Minikube"
#======================================================================

if minikube status -p "$PROFILE" &>/dev/null; then
  info "Minikube '$PROFILE' đã chạy, bỏ qua."
else
  info "Khởi tạo minikube '$PROFILE'..."
  minikube start -p "$PROFILE" --driver=docker --memory=4096 --cpus=2
fi

kubectl config use-context "$PROFILE"
kubectl get nodes

#======================================================================
banner "2/4 — Build & Load Docker images"
#======================================================================

cd "$SCRIPT_DIR"

info "Build flipkart-backend:v1..."
docker build -f Dockerfile.backend -t flipkart-backend:v1 .

info "Build flipkart-frontend:v1..."
docker build -f Dockerfile.frontend -t flipkart-frontend:v1 .

info "Load images vào minikube..."
minikube -p "$PROFILE" image load flipkart-backend:v1
minikube -p "$PROFILE" image load flipkart-frontend:v1

#======================================================================
banner "3/4 — Cài ArgoCD"
#======================================================================

kubectl create ns argocd --dry-run=client -o yaml | kubectl apply -f -

info "Cài đặt ArgoCD..."
kubectl apply --server-side -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

info "Đợi argocd-server ready..."
kubectl -n argocd rollout status deploy/argocd-server --timeout=180s

ARGO_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)

info "ArgoCD pods:"
kubectl -n argocd get pods

#======================================================================
banner "4/4 — Deploy Applications + Root"
#======================================================================

kubectl create ns flipkart --dry-run=client -o yaml | kubectl apply -f -

cd "$SCRIPT_DIR"

info "Apply root app-of-apps..."
kubectl apply -f argocd/root.yaml

info "Đợi ArgoCD sync (30s)..."
sleep 30

info "ArgoCD Applications:"
kubectl -n argocd get applications

info "Flipkart resources:"
kubectl -n flipkart get all

#======================================================================
banner "✅ Setup hoàn tất!"
#======================================================================

echo ""
info "ArgoCD UI:"
echo "  kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo "  → https://localhost:8080  (admin / $ARGO_PASS)"
echo ""
info "Flipkart App:"
echo "  kubectl -n flipkart port-forward svc/flipkart-frontend 3000:80"
echo "  → http://localhost:3000"
echo ""
