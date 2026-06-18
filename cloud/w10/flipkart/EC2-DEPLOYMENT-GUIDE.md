# 🚀 Hướng Dẫn Triển Khai W9 Full Stack Trên EC2

Tài liệu này hướng dẫn chi tiết từng bước để triển khai **toàn bộ W9 stack** (MERN Flipkart + ArgoCD + Prometheus + Grafana + Argo Rollouts + ESO + Sigstore) lên **1 EC2 t3.xlarge** trên AWS.

---

## 📋 Kiến Trúc Tổng Quan

```
┌─────────────────────────────────────────────────────┐
│                  EC2 t3.xlarge                       │
│              (4 vCPU / 16 GB / 50 GB)               │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │           Minikube (12 GB RAM)                │  │
│  │                                               │  │
│  │  ┌─────────┐ ┌────────┐ ┌──────────────────┐ │  │
│  │  │ ArgoCD  │ │  ESO   │ │ Sigstore Policy  │ │  │
│  │  │ Server  │ │        │ │   Controller     │ │  │
│  │  └─────────┘ └────────┘ └──────────────────┘ │  │
│  │                                               │  │
│  │  ┌──────────────────────────────────────────┐ │  │
│  │  │   flipkart namespace                     │ │  │
│  │  │  MongoDB ← Backend (Rollout) → Frontend  │ │  │
│  │  └──────────────────────────────────────────┘ │  │
│  │                                               │  │
│  │  ┌──────────────────────────────────────────┐ │  │
│  │  │   monitoring namespace                   │ │  │
│  │  │  Prometheus + Grafana + AlertManager     │ │  │
│  │  └──────────────────────────────────────────┘ │  │
│  │                                               │  │
│  │  ┌──────────────────────────────────────────┐ │  │
│  │  │   argo-rollouts namespace                │ │  │
│  │  │  Rollouts Controller                     │ │  │
│  │  └──────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  socat tunnels → ALB (port 30000)                   │
└─────────────────────────────────────────────────────┘
         ↑ SSH tunnel from laptop
```

---

## ⏱️ Thời Gian Ước Lượng

| Phase | Mô tả | Thời gian |
|-------|--------|-----------|
| 0 | Prerequisites | 10 phút |
| 1 | Push GHCR images | 15 phút |
| 2 | Terraform apply | 10 phút |
| 3 | Chờ init.sh + verify | 20 phút |
| 4 | Seed data + verify pods | 15 phút |
| 5 | Collect W9 evidence | 60 phút |
| 6 | Cleanup | 5 phút |
| **Tổng** | | **~2 giờ 15 phút** |

---

## Phase 0: Prerequisites

### Cần có sẵn trên laptop

- [x] AWS CLI configured (`aws sts get-caller-identity` hoạt động)
- [x] Terraform >= 1.0
- [x] Docker Desktop đang chạy
- [x] Git + GitHub account có quyền push vào repo
- [x] GitHub Personal Access Token (PAT) có scope `write:packages`

### Kiểm tra nhanh

```bash
aws sts get-caller-identity
terraform --version
docker --version
git remote -v
```

---

## Phase 1: Build & Push Images lên GHCR

> ⚠️ Bước này **BẮT BUỘC** phải làm TRƯỚC khi terraform apply. EC2 minikube sẽ pull images từ GHCR.

### 1.1. Login vào GHCR

```bash
# Tạo PAT tại: https://github.com/settings/tokens/new
# Scope cần: write:packages, read:packages
export GITHUB_TOKEN=ghp_xxxxx

echo $GITHUB_TOKEN | docker login ghcr.io -u <your-github-username> --password-stdin
```

### 1.2. Build & Push images

```bash
cd cloud/w10/flipkart

# Build backend
docker build -f Dockerfile.backend -t ghcr.io/x-brain-cdo-09/flipkart-backend:latest .

# Build frontend
docker build -f Dockerfile.frontend -t ghcr.io/x-brain-cdo-09/flipkart-frontend:latest .

# Push
docker push ghcr.io/x-brain-cdo-09/flipkart-backend:latest
docker push ghcr.io/x-brain-cdo-09/flipkart-frontend:latest
```

Hoặc dùng script có sẵn:

```bash
bash build-push-ghcr.sh
```

### 1.3. Make packages Public

1. Vào `https://github.com/orgs/X-BRAIN-CDO-09/packages`
2. Click vào `flipkart-backend` → **Package settings** → **Danger zone** → **Change visibility** → **Public**
3. Lặp lại cho `flipkart-frontend`

> Nếu không muốn public, phải tạo `imagePullSecret` trong namespace flipkart — phức tạp hơn nhiều.

### 1.4. (Optional) Sign images với Cosign cho W10 Lab 2.2

```bash
# Nếu chưa có cosign key pair:
cosign generate-key-pair

# Sign images
cosign sign --key cosign.key ghcr.io/x-brain-cdo-09/flipkart-backend:latest
cosign sign --key cosign.key ghcr.io/x-brain-cdo-09/flipkart-frontend:latest
```

### 1.5. Commit & Push code changes

```bash
# Đảm bảo các thay đổi k8s manifests (GHCR images) đã được commit
cd <repo-root>
git add -A
git commit -m "feat: switch to GHCR images for EC2 deployment"
git push origin main
```

---

## Phase 2: Terraform Apply

### 2.1. Initialize & Plan

```bash
cd cloud/w10/flipkart/terraform

terraform init
terraform plan
```

### 2.2. Verify plan output

Kiểm tra các thay đổi quan trọng:
- `instance_type = "t3.xlarge"` ✅
- `volume_size = 50` ✅
- ALB, security groups, IAM role đều đúng

### 2.3. Apply

```bash
terraform apply -auto-approve
```

### 2.4. Lưu output

```bash
terraform output
```

Ghi lại:
- `ec2_public_ip` — dùng để SSH
- `alb_dns_name` — dùng để truy cập Flipkart app qua browser

### 2.5. Lưu SSH key

```bash
# Key đã tự tạo bởi Terraform
ls -la flipkart-w10-key.pem
```

---

## Phase 3: Chờ Init & SSH vào EC2

### 3.1. Chờ init.sh hoàn thành

init.sh mất **khoảng 10-15 phút** để cài:
1. Docker, kubectl, helm, minikube (~2 phút)
2. Minikube start (~3 phút)
3. ArgoCD install + wait (~3 phút)
4. ESO + Sigstore install (~3 phút)
5. Root app bootstrap (~1 phút)

### 3.2. Kiểm tra cloud-init log

```bash
# SSH vào EC2
ssh -i flipkart-w10-key.pem ubuntu@<EC2_PUBLIC_IP>

# Xem log real-time
tail -f /var/log/cloud-init-output.log

# Hoặc kiểm tra cloud-init đã xong chưa
cloud-init status
# Kết quả mong muốn: status: done
```

### 3.3. Verify cơ bản

```bash
# Trên EC2
minikube status
kubectl get nodes
kubectl -n argocd get pods
```

---

## Phase 4: Verify & Seed Data

### 4.1. Chạy script verify tự động

```bash
# Clone repo về EC2 (hoặc download scripts)
git clone https://github.com/X-BRAIN-CDO-09/PhanLeThanhHoang-aws-accelerator-p2.git /tmp/repo
cd /tmp/repo/cloud/w10/flipkart

# Chạy verify script
bash ec2-verify.sh
```

Hoặc verify thủ công:

### 4.2. Kiểm tra ArgoCD applications

```bash
kubectl -n argocd get applications
```

Output mong muốn:
```
NAME                    SYNC STATUS   HEALTH STATUS
root                    Synced        Healthy
flipkart-base           Synced        Healthy
flipkart-mongodb        Synced        Healthy
flipkart-backend        Synced        Healthy
flipkart-frontend       Synced        Healthy
kube-prometheus-stack   Synced        Healthy
argo-rollouts           Synced        Healthy
flipkart-eso            Synced        Healthy
flipkart-policy         Synced        Healthy
```

### 4.3. Kiểm tra tất cả pods

```bash
kubectl get pods -A | grep -v kube-system
```

### 4.4. Seed MongoDB data

```bash
# Nếu đã chạy ec2-verify.sh thì bỏ qua bước này
# Nếu chạy thủ công:

curl -fsSL "https://raw.githubusercontent.com/X-BRAIN-CDO-09/PhanLeThanhHoang-aws-accelerator-p2/main/cloud/w10/flipkart/seed.js" -o /tmp/seed.js

kubectl -n flipkart create configmap flipkart-seed-script \
  --from-file=seed.js=/tmp/seed.js --dry-run=client -o yaml | kubectl apply -f -

kubectl -n flipkart delete job flipkart-seed --ignore-not-found

kubectl apply -f - <<'EOF'
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
```

### 4.5. Tạo SSH tunnel từ laptop

**Mở terminal MỚI trên laptop** (giữ terminal này chạy suốt):

```bash
ssh -i flipkart-w10-key.pem \
  -L 8080:127.0.0.1:8080 \
  -L 3000:127.0.0.1:3000 \
  -L 3001:127.0.0.1:3001 \
  -L 9090:127.0.0.1:9090 \
  -L 9093:127.0.0.1:9093 \
  ubuntu@<EC2_PUBLIC_IP>
```

**Trên EC2** (trong SSH session), start port-forwards:

```bash
# Kill existing
pkill -f "kubectl.*port-forward" 2>/dev/null || true

# ArgoCD
nohup kubectl -n argocd port-forward svc/argocd-server 8080:443 --address 0.0.0.0 > /tmp/argocd-pf.log 2>&1 &

# Flipkart App
nohup kubectl -n flipkart port-forward svc/flipkart-frontend 3000:80 --address 0.0.0.0 > /tmp/flipkart-pf.log 2>&1 &

# Grafana
nohup kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3001:80 --address 0.0.0.0 > /tmp/grafana-pf.log 2>&1 &

# Prometheus
nohup kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090 --address 0.0.0.0 > /tmp/prom-pf.log 2>&1 &

# AlertManager
nohup kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093 --address 0.0.0.0 > /tmp/am-pf.log 2>&1 &
```

### 4.6. Verify qua browser (trên laptop)

| Service | URL | Credentials |
|---------|-----|-------------|
| ArgoCD | https://127.0.0.1:8080 | admin / `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' \| base64 -d` |
| Flipkart App | http://127.0.0.1:3000 | — |
| Grafana | http://127.0.0.1:3001 | admin / prom-operator |
| Prometheus | http://127.0.0.1:9090 | — |
| AlertManager | http://127.0.0.1:9093 | — |
| Flipkart (qua ALB) | http://\<alb_dns_name\> | — |

---

## Phase 5: Thu Thập Evidence W9

### Evidence 1: ArgoCD App-of-Apps Synced + Healthy

1. Mở https://127.0.0.1:8080
2. Login với admin / \<password\>
3. **Chụp screenshot** tất cả apps đều `Synced` + `Healthy`
4. Lưu: `assets/Ảnh1.png`

### Evidence 2: Prometheus Target Backend UP

1. Mở http://127.0.0.1:9090/targets
2. Tìm target `serviceMonitor/flipkart/flipkart-backend`
3. Trạng thái phải là **UP**
4. **Chụp screenshot** → `assets/Ảnh2.png`

### Evidence 3: PromQL Success Rate

1. Mở http://127.0.0.1:9090/graph
2. Paste query:
   ```
   sum(rate(http_request_duration_seconds_count{namespace="flipkart", status_code!~"5.."}[2m])) / sum(rate(http_request_duration_seconds_count{namespace="flipkart"}[2m]))
   ```
3. Kết quả phải = **1** (100% success rate)
4. **Chụp screenshot** → `assets/Ảnh3.png`

> 💡 Nếu chưa có metrics, tạo traffic trước:
> ```bash
> for i in $(seq 1 100); do curl -s http://127.0.0.1:3000 > /dev/null; done
> ```

### Evidence 4: Bad Release → AlertManager Firing

**Trên laptop** (KHÔNG phải EC2):

```bash
cd cloud/w9/flipkart/k8s/backend
```

Sửa `rollout.yaml`:
```yaml
env:
  - name: ERROR_RATE
    value: "0.5"      # ← đổi từ "0" thành "0.5"
  - name: VERSION
    value: "v2-bad"   # ← đổi từ "v1" thành "v2-bad"
```

```bash
git add -A
git commit -m "bad release: ERROR_RATE=0.5"
git push origin main
```

Đợi 2-3 phút để ArgoCD sync, sau đó:

1. Mở http://127.0.0.1:9093
2. Alert `HighErrorRate` phải đang **FIRING**
3. **Chụp screenshot** → `assets/Ảnh4.png`

### Evidence 5: Canary Paused at 10%/50%

Trên EC2:
```bash
kubectl argo rollouts get rollout flipkart-backend -n flipkart --watch
```

1. Chụp khi traffic đang ở bước **10%** hoặc **50%**
2. **Chụp screenshot** → `assets/Ảnh6.png`

### Evidence 6: AnalysisRun Fail → Auto-Abort

```bash
kubectl -n flipkart get analysisrun
kubectl argo rollouts get rollout flipkart-backend -n flipkart
```

1. AnalysisRun phải fail (success rate < 95%)
2. Rollout phải auto-abort → trạng thái `Degraded`
3. **Chụp screenshot** → `assets/Ảnh8.png`

### Evidence 7: Git Revert → ArgoCD Reconcile

**Trên laptop**:

```bash
git revert HEAD --no-edit
git push origin main
```

1. Đợi 2-3 phút
2. Kiểm tra ArgoCD → tất cả apps Synced + Healthy lại
3. Rollout trở về stable
4. **Chụp screenshot** → `assets/Ảnh9.png`

---

## Phase 6: Cleanup

### 6.1. Destroy infrastructure

```bash
cd cloud/w10/flipkart/terraform
terraform destroy -auto-approve
```

### 6.2. Verify

```bash
# Kiểm tra không còn tài nguyên
aws ec2 describe-instances --filters "Name=tag:Name,Values=flipkart-*" --query "Reservations[].Instances[].State.Name"
```

---

## 🔥 Troubleshooting

### init.sh không chạy xong

```bash
# Xem log chi tiết
cat /var/log/cloud-init-output.log

# Restart minikube nếu bị treo
minikube stop && minikube start --driver=docker --cpus=4 --memory=12288
```

### Pods ImagePullBackOff

```bash
kubectl -n flipkart describe pod <pod-name>
```

Nguyên nhân phổ biến:
- GHCR packages chưa public → make public trên GitHub
- Image tag sai → verify `docker pull ghcr.io/x-brain-cdo-09/flipkart-backend:latest`

### ArgoCD app OutOfSync

```bash
# Force sync
kubectl -n argocd patch application <app-name> --type merge -p '{"operation":{"sync":{"force":true}}}'

# Hoặc qua UI: click Sync → Force
```

### OOM / Pods bị Evicted

```bash
# Kiểm tra tài nguyên
kubectl top nodes
kubectl top pods -A --sort-by=memory

# Nếu OOM, giảm Prometheus retention:
# Sửa argocd/apps/kube-prometheus-stack.yaml → thêm:
#   prometheus:
#     prometheusSpec:
#       retention: 1h
#       resources:
#         limits:
#           memory: 1Gi
```

### Port-forward bị disconnect

```bash
# Restart port-forward
pkill -f "kubectl.*port-forward" 2>/dev/null || true
# Chạy lại lệnh port-forward ở Phase 4.5
```

### Cosign verification fails (W10 Lab 2.2)

```bash
# Kiểm tra policy-controller logs
kubectl -n cosign-system logs deploy/policy-controller-webhook

# Nếu block pods → disable tạm
kubectl label namespace flipkart policy.sigstore.dev/include- --overwrite
```

---

## 📁 Cấu Trúc Files Đã Thay Đổi

```
cloud/w10/flipkart/
├── terraform/
│   ├── variables.tf                    # t3.large → t3.xlarge
│   └── modules/compute/
│       ├── main.tf                     # volume_size: 30 → 50 GB
│       └── init.sh                     # Rewritten: 4CPU/12GB, helm repos,
│                                       #   ArgoCD wait, root app bootstrap,
│                                       #   socat tunnels
├── k8s/
│   ├── backend/rollout.yaml            # GHCR image
│   └── frontend/deployment.yaml        # GHCR image
├── k8s-policy/
│   └── cluster-image-policy.yaml       # Removed glob "**" catch-all
├── build-push-ghcr.sh                  # [NEW] Build & push script
├── ec2-verify.sh                       # [NEW] Phase 4 verify script
├── ec2-evidence.sh                     # [NEW] Phase 5 evidence script
├── run-labs.sh                         # Seed job → GHCR image
└── EC2-DEPLOYMENT-GUIDE.md             # [NEW] This guide

cloud/w9/flipkart/k8s/
├── backend/rollout.yaml                # GHCR image
└── frontend/deployment.yaml            # GHCR image
```

---

## 💰 Chi Phí Ước Tính

| Resource | Giá/giờ | Thời gian | Tổng |
|----------|---------|-----------|------|
| t3.xlarge EC2 | ~$0.166 | ~3 giờ | ~$0.50 |
| ALB | ~$0.025 | ~3 giờ | ~$0.08 |
| EBS 50GB gp3 | ~$0.004 | ~3 giờ | ~$0.01 |
| Secrets Manager | ~$0.40/secret/tháng | 1 secret | ~$0.01 |
| **Tổng** | | | **< $1.00** |

> ⚡ Nhớ `terraform destroy` ngay sau khi xong để tránh phát sinh chi phí!
