#!/bin/bash
set -euo pipefail

#======================================================================
# GitOps Lab — Flipkart: Setup & Deploy
# Chạy từ thư mục: cloud/w9/flipkart/
# Yêu cầu: docker, minikube, kubectl đã cài sẵn
#======================================================================

PROFILE="w9"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARGOCD_PORT_FORWARD_LOG="$SCRIPT_DIR/argocd-port-forward.log"
FLIPKART_PORT_FORWARD_LOG="$SCRIPT_DIR/flipkart-port-forward.log"
MONGO_PORT_FORWARD_LOG="$SCRIPT_DIR/mongo-port-forward.log"

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

start_mongo_port_forward() {
  info "Mở MongoDB port-forward để seed data..."

  if (echo > /dev/tcp/127.0.0.1/27017) >/dev/null 2>&1; then
    info "Port 27017 đã có sẵn, dùng lại kết nối hiện có."
    return 0
  fi

  nohup kubectl -n flipkart port-forward svc/mongo-svc 27017:27017 --address 127.0.0.1 \
    >"$MONGO_PORT_FORWARD_LOG" 2>&1 &
  MONGO_PORT_FORWARD_PID=$!

  sleep 3
}

seed_flipkart_data() {
  info "Chạy seed data..."
  kubectl -n flipkart run flipkart-seed --rm -i --restart=Never \
    --image=flipkart-backend:v1 \
    --env="MONGO_URI=mongodb://mongo-svc:27017/flipkart" \
    --command -- node seed.js

  info "Seed data hoàn tất."
}

start_argocd_port_forward() {
  info "Mở ArgoCD portal ở https://127.0.0.1:8080 ..."

  if curl -kfsS https://127.0.0.1:8080 >/dev/null 2>&1; then
    info "Port 8080 đã có sẵn, dùng lại portal hiện có."
    return 0
  fi

  nohup kubectl -n argocd port-forward svc/argocd-server 8080:443 --address 127.0.0.1 \
    >"$ARGOCD_PORT_FORWARD_LOG" 2>&1 &

  sleep 3

  if curl -kfsS https://127.0.0.1:8080 >/dev/null 2>&1; then
    info "ArgoCD portal đã sẵn sàng."
    info "Log port-forward: $ARGOCD_PORT_FORWARD_LOG"
  else
    info "Không xác nhận được ArgoCD portal ngay lập tức. Kiểm tra log: $ARGOCD_PORT_FORWARD_LOG"
  fi
}

start_flipkart_port_forward() {
  info "Mở Flipkart app ở http://127.0.0.1:3000 ..."

  if curl -fsS http://127.0.0.1:3000 >/dev/null 2>&1; then
    info "Port 3000 đã có sẵn, dùng lại app hiện có."
    return 0
  fi

  nohup kubectl -n flipkart port-forward svc/flipkart-frontend 3000:80 --address 127.0.0.1 \
    >"$FLIPKART_PORT_FORWARD_LOG" 2>&1 &

  sleep 3

  if curl -fsS http://127.0.0.1:3000 >/dev/null 2>&1; then
    info "Flipkart app đã sẵn sàng."
    info "Log port-forward: $FLIPKART_PORT_FORWARD_LOG"
  else
    info "Không xác nhận được Flipkart app ngay lập tức. Kiểm tra log: $FLIPKART_PORT_FORWARD_LOG"
  fi
}

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

info "Đợi MongoDB sẵn sàng để seed..."
kubectl -n flipkart rollout status deploy/mongodb --timeout=180s

start_mongo_port_forward
seed_flipkart_data

if [ -n "${MONGO_PORT_FORWARD_PID:-}" ]; then
  kill "$MONGO_PORT_FORWARD_PID" >/dev/null 2>&1 || true
fi

info "Flipkart resources:"
kubectl -n flipkart get all

start_argocd_port_forward
start_flipkart_port_forward

#======================================================================
banner "✅ Setup hoàn tất!"
#======================================================================

echo ""
info "ArgoCD UI:"
echo "  https://127.0.0.1:8080  (admin / $ARGO_PASS)"
echo "  Log: $ARGOCD_PORT_FORWARD_LOG"
echo ""
info "Flipkart App:"
echo "  http://127.0.0.1:3000"
echo "  Log: $FLIPKART_PORT_FORWARD_LOG"
echo ""
