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

seed_flipkart_data() {
  info "Chạy seed data..."

  kubectl -n flipkart delete configmap flipkart-seed-script --ignore-not-found >/dev/null 2>&1 || true
  kubectl -n flipkart create configmap flipkart-seed-script \
    --from-file=seed.js="$SCRIPT_DIR/seed.js" \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl -n flipkart delete job flipkart-seed --ignore-not-found >/dev/null 2>&1 || true

  kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: flipkart-seed
  namespace: flipkart
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      volumes:
        - name: seed-script
          configMap:
            name: flipkart-seed-script
      containers:
        - name: seed
          image: flipkart-backend:v1
          imagePullPolicy: Never
          command: ["node", "/app/seed.js"]
          env:
            - name: MONGO_URI
              value: mongodb://mongo-svc:27017/flipkart
          volumeMounts:
            - name: seed-script
              mountPath: /app/seed.js
              subPath: seed.js
              readOnly: true
EOF

  kubectl -n flipkart wait --for=condition=complete job/flipkart-seed --timeout=180s

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

seed_flipkart_data

info "Flipkart resources:"
kubectl -n flipkart get all

start_argocd_port_forward
start_flipkart_port_forward

#======================================================================
banner "5/5 — Đợi Observability & Canary stack sẵn sàng"
#======================================================================

info "Đợi namespace monitoring xuất hiện..."
for _ in $(seq 1 60); do
  if kubectl get ns monitoring >/dev/null 2>&1; then
    break
  fi
  sleep 3
done

info "Đợi Prometheus stack khởi động (có thể mất 3-5 phút)..."
kubectl -n monitoring rollout status deploy/kube-prometheus-stack-grafana --timeout=300s 2>/dev/null || \
  info "Grafana chưa sẵn sàng, có thể cần thêm thời gian."
kubectl -n monitoring rollout status deploy/kube-prometheus-stack-kube-prom-operator --timeout=300s 2>/dev/null || \
  info "Prometheus Operator chưa sẵn sàng."

info "Đợi Argo Rollouts controller..."
kubectl -n argo-rollouts rollout status deploy/argo-rollouts --timeout=180s 2>/dev/null || \
  info "Argo Rollouts chưa sẵn sàng, có thể cần thêm thời gian."

# --- Port-forward Grafana ---
info "Mở Grafana ở http://127.0.0.1:3001 ..."
if curl -fsS http://127.0.0.1:3001 >/dev/null 2>&1; then
  info "Port 3001 đã có sẵn."
else
  nohup kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3001:80 --address 0.0.0.0 \
    >"$SCRIPT_DIR/grafana-port-forward.log" 2>&1 &
  sleep 3
fi

# --- Port-forward Prometheus ---
info "Mở Prometheus ở http://127.0.0.1:9090 ..."
if curl -fsS http://127.0.0.1:9090 >/dev/null 2>&1; then
  info "Port 9090 đã có sẵn."
else
  nohup kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090 --address 0.0.0.0 \
    >"$SCRIPT_DIR/prometheus-port-forward.log" 2>&1 &
  sleep 2
fi

# --- Port-forward AlertManager ---
info "Mở AlertManager ở http://127.0.0.1:9093 ..."
if curl -fsS http://127.0.0.1:9093 >/dev/null 2>&1; then
  info "Port 9093 đã có sẵn."
else
  nohup kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093 --address 0.0.0.0 \
    >"$SCRIPT_DIR/alertmanager-port-forward.log" 2>&1 &
  sleep 2
fi

# --- Port-forward Argo Rollouts Dashboard ---
info "Mở Argo Rollouts Dashboard ở http://127.0.0.1:3100 ..."
if curl -fsS http://127.0.0.1:3100 >/dev/null 2>&1; then
  info "Port 3100 đã có sẵn."
else
  nohup kubectl argo rollouts dashboard -p 3100 \
    >"$SCRIPT_DIR/rollouts-dashboard.log" 2>&1 &
  sleep 2
fi

#======================================================================
banner "✅ Setup hoàn tất!"
#======================================================================

echo ""
info "╔══════════════════════════════════════════════════════════╗"
info "║           TẤT CẢ GIAO DIỆN CỦA BÀI LAB W9             ║"
info "╚══════════════════════════════════════════════════════════╝"
echo ""
info "1. ArgoCD (GitOps Dashboard):"
echo "   🔗 https://127.0.0.1:8080"
echo "   👤 admin / $ARGO_PASS"
echo "   📝 Quản lý App-of-apps, Sync Waves, Self-heal, Rollback"
echo ""
info "2. Flipkart App:"
echo "   🔗 http://127.0.0.1:3000"
echo "   📝 Ứng dụng chính (Frontend + Backend)"
echo ""
info "3. Grafana (Observability Dashboard):"
echo "   🔗 http://127.0.0.1:3001"
echo "   👤 admin / prom-operator"
echo "   📝 Xem biểu đồ metrics, tạo Dashboard SLO/SLI"
echo ""
info "4. Prometheus (Metrics Query):"
echo "   🔗 http://127.0.0.1:9090"
echo "   📝 Truy vấn trực tiếp metrics, kiểm tra Targets, Rules"
echo "   💡 Thử query: rate(http_request_duration_seconds_count{namespace=\"flipkart\"}[2m])"
echo ""
info "5. AlertManager (Cảnh báo):"
echo "   🔗 http://127.0.0.1:9093"
echo "   📝 Xem các Alert đang firing, cấu hình route email"
echo ""
info "6. Argo Rollouts Dashboard (Canary):"
echo "   🔗 http://127.0.0.1:3100"
echo "   📝 Theo dõi quá trình Canary: traffic split, AnalysisRun, Auto-abort"
echo "   💡 Chọn namespace 'flipkart' để xem Rollout"
echo ""
info "═══════════════════════════════════════════════════════════"
info "📌 Lệnh hữu ích:"
echo "   kubectl argo rollouts get rollout flipkart-backend -n flipkart --watch"
echo "   kubectl -n flipkart get analysisrun"
echo ""
