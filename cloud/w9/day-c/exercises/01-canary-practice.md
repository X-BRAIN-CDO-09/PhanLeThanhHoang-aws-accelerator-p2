# Bài tập Day C: Canary Deployment Practice

## Yêu cầu

### 1. Cài đặt Argo Rollouts
Cài đặt Argo Rollouts controller vào cụm Kubernetes.
```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```
Cài đặt Argo Rollouts kubectl plugin để dễ dàng điều khiển qua dòng lệnh:
```bash
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x ./kubectl-argo-rollouts-linux-amd64
sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

### 2. Chuyển đổi Deployment sang Rollout
1. Copy file `Deployment` của Counter-App. Đổi `kind: Deployment` thành `kind: Rollout`.
2. Thay đổi phần `spec.strategy` để sử dụng Canary:
   - Step 1: `setWeight: 20`
   - Step 2: `pause: {}` (Dừng lại vĩnh viễn cho đến khi được promote bằng tay)
3. Apply file Rollout.
4. Đẩy bản cập nhật mới (vd: thay đổi image tag). Quan sát trên CLI bằng lệnh:
   `kubectl argo rollouts get rollout <tên-rollout> --watch`
5. Thử dùng lệnh promote để chuyển sang bước tiếp theo (hoàn thành 100%):
   `kubectl argo rollouts promote <tên-rollout>`

### 3. Tích hợp AnalysisTemplate (Auto-Promote / Auto-Abort)
1. Viết một `AnalysisTemplate` truy vấn Prometheus (kiểm tra tỷ lệ lỗi).
2. Viết file `Rollout` mới sử dụng AnalysisTemplate vừa tạo:
   - Step 1: `setWeight: 20`
   - Step 2: Chạy `analysis` trong vòng 2 phút. Nếu thành công, sang step 3.
   - Step 3: `setWeight: 100`.
3. Khởi tạo một phiên bản ứng dụng chạy tốt. Chờ nó đạt 100%.
4. Khởi tạo một phiên bản ứng dụng CỐ TÌNH GÂY LỖI.
5. Dùng tool `k6` hoặc `vegeta` (hoặc curl trong vòng lặp) để bắn traffic liên tục vào Ingress/Service của ứng dụng.
6. Quan sát màn hình theo dõi Rollout, chứng kiến cảnh nó tự động **Abort** và **Scaledown** bản lỗi do không qua được bài test của Prometheus.
