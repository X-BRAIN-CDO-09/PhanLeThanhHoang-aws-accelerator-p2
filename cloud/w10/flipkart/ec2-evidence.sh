#!/bin/bash
# Phase 5: Re-run W9 Evidence Scenarios on EC2
# This script automates the W9 "Ship Smartly" evidence collection.
# Run this AFTER ec2-verify.sh completes successfully.
#
# Usage: bash ec2-evidence.sh
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

###############################################################################
banner "Evidence 1: ArgoCD App-of-Apps Synced + Healthy"
###############################################################################

info "Kiểm tra tất cả ArgoCD Applications:"
kubectl -n argocd get applications -o wide
echo ""
info "📸 Chụp screenshot ArgoCD UI tại https://127.0.0.1:8080"
info "   → Tất cả apps phải Synced + Healthy"
info "   → Lưu thành: assets/Ảnh1.png"
echo ""
read -p "Nhấn Enter sau khi đã chụp screenshot Evidence 1..."

###############################################################################
banner "Evidence 2: Prometheus Target Backend UP"
###############################################################################

info "Kiểm tra Prometheus targets:"
echo ""
info "📸 Mở Prometheus UI: http://127.0.0.1:9090/targets"
info "   → Tìm target 'flipkart-backend' với trạng thái UP"
info "   → Lưu thành: assets/Ảnh2.png"
echo ""

# Generate some traffic to produce metrics
info "Tạo traffic để Prometheus có metrics..."
for i in $(seq 1 50); do
  curl -s http://127.0.0.1:3000 > /dev/null 2>&1 || true
  curl -s http://127.0.0.1:3000/api/v1/products > /dev/null 2>&1 || true
done
info "Đã gửi 100 requests. Đợi 30s để Prometheus scrape..."
sleep 30

read -p "Nhấn Enter sau khi đã chụp screenshot Evidence 2..."

###############################################################################
banner "Evidence 3: PromQL Success Rate Query"
###############################################################################

info "📸 Mở Prometheus UI: http://127.0.0.1:9090/graph"
info "   → Paste query này:"
echo ""
echo '   sum(rate(http_request_duration_seconds_count{namespace="flipkart", status_code!~"5.."}[2m])) / sum(rate(http_request_duration_seconds_count{namespace="flipkart"}[2m]))'
echo ""
info "   → Kết quả phải = 1 (100% success rate)"
info "   → Lưu thành: assets/Ảnh3.png"
echo ""
read -p "Nhấn Enter sau khi đã chụp screenshot Evidence 3..."

###############################################################################
banner "Evidence 4: Trigger Bad Release → AlertManager Firing"
###############################################################################

info "Chuẩn bị push bad release (ERROR_RATE=0.5)..."
info ""
info "⚠️  TRÊN LAPTOP (không phải EC2), chạy các lệnh sau:"
echo ""
echo "   cd cloud/w9/flipkart/k8s/backend"
echo "   # Sửa rollout.yaml: đổi ERROR_RATE từ \"0\" thành \"0.5\""
echo "   # Sửa rollout.yaml: đổi VERSION từ \"v1\" thành \"v2-bad\""
echo "   git add -A && git commit -m 'bad release: ERROR_RATE=0.5'"
echo "   git push origin main"
echo ""
info "Sau khi push, ArgoCD sẽ tự sync trong ~3 phút."
info "Đợi 2-3 phút rồi kiểm tra AlertManager: http://127.0.0.1:9093"
echo ""
info "📸 Chụp screenshot AlertManager đang firing"
info "   → Lưu thành: assets/Ảnh4.png"
echo ""
read -p "Nhấn Enter sau khi đã push bad release VÀ chụp screenshot Evidence 4..."

###############################################################################
banner "Evidence 5+6: Argo Rollouts Canary Paused"
###############################################################################

info "Kiểm tra trạng thái Rollout:"
kubectl -n flipkart get rollout flipkart-backend -o wide 2>/dev/null || \
  warn "Rollout chưa có, đợi ArgoCD sync..."
echo ""
info "📸 Mở ArgoCD hoặc dùng lệnh để xem canary steps:"
echo "   kubectl argo rollouts get rollout flipkart-backend -n flipkart --watch"
echo ""
info "   → Chụp khi Canary ở bước 10% hoặc 50%"
info "   → Lưu thành: assets/Ảnh6.png"
echo ""
read -p "Nhấn Enter sau khi đã chụp screenshot Evidence 5/6..."

###############################################################################
banner "Evidence 7: AnalysisRun Fail → Auto-Abort"
###############################################################################

info "Kiểm tra AnalysisRun:"
kubectl -n flipkart get analysisrun 2>/dev/null || true
echo ""
info "📸 Chụp screenshot khi AnalysisRun fail và Canary auto-abort"
info "   → kubectl argo rollouts get rollout flipkart-backend -n flipkart"
info "   → Lưu thành: assets/Ảnh8.png"
echo ""
read -p "Nhấn Enter sau khi đã chụp screenshot Evidence 7..."

###############################################################################
banner "Evidence 8: Git Revert → ArgoCD Reconcile"
###############################################################################

info "⚠️  TRÊN LAPTOP, chạy:"
echo ""
echo "   git revert HEAD --no-edit"
echo "   git push origin main"
echo ""
info "Sau khi push, ArgoCD sẽ tự reconcile trong ~3 phút."
info "📸 Chụp screenshot terminal git revert + ArgoCD synced lại"
info "   → Lưu thành: assets/Ảnh9.png"
echo ""
read -p "Nhấn Enter sau khi đã chụp screenshot Evidence 8..."

###############################################################################
banner "✅ Evidence Collection Complete!"
###############################################################################

info "Tất cả evidence đã được thu thập."
info ""
info "Danh sách files cần có trong assets/:"
echo "   assets/Ảnh1.png  — ArgoCD App-of-Apps Synced+Healthy"
echo "   assets/Ảnh2.png  — Prometheus Target Backend UP"
echo "   assets/Ảnh3.png  — PromQL Success Rate = 1"
echo "   assets/Ảnh4.png  — AlertManager Firing (bad release)"
echo "   assets/Ảnh6.png  — Canary Paused at 10%/50%"
echo "   assets/Ảnh8.png  — AnalysisRun Fail + Auto-Abort"
echo "   assets/Ảnh9.png  — Git Revert + ArgoCD Reconcile"
echo ""
info "Tiếp theo: chạy 'terraform destroy' để dọn dẹp EC2."
echo ""
