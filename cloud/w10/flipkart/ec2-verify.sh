#!/bin/bash
# Phase 4: Verify & Setup on EC2
# Run this AFTER SSH-ing into the EC2 instance.
# Usage: bash ec2-verify.sh
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

banner() {
  echo ""
  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}  $1${NC}"
  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo ""
}

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$SCRIPT_DIR/logs"

###############################################################################
banner "1/6 — Check Minikube Status"
###############################################################################

if minikube status &>/dev/null; then
  info "✅ Minikube is running"
  minikube status
else
  error "❌ Minikube is NOT running. Check /var/log/cloud-init-output.log"
  echo "   tail -f /var/log/cloud-init-output.log"
  exit 1
fi

###############################################################################
banner "2/6 — Check ArgoCD Applications"
###############################################################################

info "Waiting for ArgoCD to be ready..."
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s

info "ArgoCD Applications status:"
kubectl -n argocd get applications

ARGO_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)
info "ArgoCD admin password: $ARGO_PASS"

###############################################################################
banner "3/6 — Wait for Core Pods"
###############################################################################

# Wait for flipkart namespace
info "Waiting for flipkart namespace..."
for i in $(seq 1 60); do
  if kubectl get ns flipkart &>/dev/null; then
    info "✅ Namespace flipkart exists"
    break
  fi
  sleep 5
done

# Wait for MongoDB
info "Waiting for MongoDB deployment..."
for i in $(seq 1 60); do
  if kubectl get deploy mongodb -n flipkart &>/dev/null; then
    info "✅ MongoDB deployment found"
    break
  fi
  sleep 5
done
kubectl -n flipkart rollout status deploy/mongodb --timeout=300s

# Wait for backend rollout
info "Waiting for backend rollout..."
for i in $(seq 1 60); do
  if kubectl get rollout flipkart-backend -n flipkart &>/dev/null 2>&1; then
    info "✅ Backend rollout found"
    break
  fi
  sleep 5
done

# Wait for frontend
info "Waiting for frontend deployment..."
for i in $(seq 1 60); do
  if kubectl get deploy flipkart-frontend -n flipkart &>/dev/null; then
    info "✅ Frontend deployment found"
    break
  fi
  sleep 5
done
kubectl -n flipkart rollout status deploy/flipkart-frontend --timeout=300s

###############################################################################
banner "4/6 — Seed MongoDB Data"
###############################################################################

info "Creating seed ConfigMap..."
kubectl -n flipkart delete configmap flipkart-seed-script --ignore-not-found >/dev/null 2>&1 || true

# Download seed.js from repo
SEED_URL="https://raw.githubusercontent.com/X-BRAIN-CDO-09/PhanLeThanhHoang-aws-accelerator-p2/main/cloud/w10/flipkart/seed.js"
curl -fsSL "$SEED_URL" -o /tmp/seed.js

kubectl -n flipkart create configmap flipkart-seed-script \
  --from-file=seed.js=/tmp/seed.js \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n flipkart delete job flipkart-seed --ignore-not-found >/dev/null 2>&1 || true

info "Running seed job..."
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: flipkart-seed
  namespace: flipkart
spec:
  backoffLimit: 2
  template:
    spec:
      restartPolicy: Never
      volumes:
        - name: seed-script
          configMap:
            name: flipkart-seed-script
      containers:
        - name: seed
          image: ghcr.io/x-brain-cdo-09/flipkart-backend:latest
          imagePullPolicy: IfNotPresent
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
info "✅ Seed data complete"

###############################################################################
banner "5/6 — Wait for Observability Stack"
###############################################################################

info "Waiting for monitoring namespace..."
for i in $(seq 1 60); do
  if kubectl get ns monitoring &>/dev/null; then
    info "✅ Namespace monitoring exists"
    break
  fi
  sleep 5
done

info "Waiting for Prometheus stack (this may take 3-5 minutes)..."
kubectl -n monitoring rollout status deploy/kube-prometheus-stack-grafana --timeout=600s 2>/dev/null || \
  warn "Grafana not ready yet, may need more time."
kubectl -n monitoring rollout status deploy/kube-prometheus-stack-kube-prom-operator --timeout=600s 2>/dev/null || \
  warn "Prometheus Operator not ready yet."

info "Waiting for Argo Rollouts controller..."
kubectl -n argo-rollouts rollout status deploy/argo-rollouts --timeout=300s 2>/dev/null || \
  warn "Argo Rollouts not ready yet."

###############################################################################
banner "6/6 — Start Port-Forwards"
###############################################################################

# Kill any existing port-forwards
pkill -f "kubectl.*port-forward" 2>/dev/null || true
sleep 2

info "Starting port-forwards..."

nohup kubectl -n argocd port-forward svc/argocd-server 8080:443 --address 0.0.0.0 \
  >"$SCRIPT_DIR/logs/argocd.log" 2>&1 &
info "ArgoCD:      https://127.0.0.1:8080"

nohup kubectl -n flipkart port-forward svc/flipkart-frontend 3000:80 --address 0.0.0.0 \
  >"$SCRIPT_DIR/logs/flipkart.log" 2>&1 &
info "Flipkart:    http://127.0.0.1:3000"

nohup kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3001:80 --address 0.0.0.0 \
  >"$SCRIPT_DIR/logs/grafana.log" 2>&1 &
info "Grafana:     http://127.0.0.1:3001"

nohup kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090 --address 0.0.0.0 \
  >"$SCRIPT_DIR/logs/prometheus.log" 2>&1 &
info "Prometheus:  http://127.0.0.1:9090"

nohup kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093 --address 0.0.0.0 \
  >"$SCRIPT_DIR/logs/alertmanager.log" 2>&1 &
info "AlertManager: http://127.0.0.1:9093"

sleep 3

###############################################################################
banner "✅ EC2 Setup Complete!"
###############################################################################

echo ""
info "╔══════════════════════════════════════════════════════════╗"
info "║           ALL SERVICES RUNNING ON EC2                   ║"
info "╚══════════════════════════════════════════════════════════╝"
echo ""
info "From your LAPTOP, create SSH tunnel:"
echo "   ssh -i flipkart-w10-key.pem \\"
echo "     -L 8080:127.0.0.1:8080 \\"
echo "     -L 3000:127.0.0.1:3000 \\"
echo "     -L 3001:127.0.0.1:3001 \\"
echo "     -L 9090:127.0.0.1:9090 \\"
echo "     -L 9093:127.0.0.1:9093 \\"
echo "     ubuntu@<EC2_PUBLIC_IP>"
echo ""
info "Then open in browser:"
echo "   1. ArgoCD:      https://127.0.0.1:8080  (admin / $ARGO_PASS)"
echo "   2. Flipkart:    http://127.0.0.1:3000"
echo "   3. Grafana:     http://127.0.0.1:3001   (admin / prom-operator)"
echo "   4. Prometheus:  http://127.0.0.1:9090"
echo "   5. AlertManager: http://127.0.0.1:9093"
echo ""
info "All pods:"
kubectl get pods -A | grep -v kube-system
echo ""
