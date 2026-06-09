# Giới thiệu Argo Rollouts và Progressive Delivery

## 1. Hạn chế của Kubernetes Deployment tiêu chuẩn
Object `Deployment` mặc định của Kubernetes thực hiện chiến lược **Rolling Update**:
- Tạo một Pod mới. Đợi Pod mới lên trạng thái `Ready`.
- Tắt bớt một Pod cũ. Lặp lại quá trình cho đến khi tất cả thay thế xong.

**Vấn đề:** Trạng thái `Ready` của Pod chỉ nói lên việc tiến trình ứng dụng đã khởi động thành công. Nó **không** chứng minh được ứng dụng xử lý đúng logic hay không có lỗi 500. Nếu phiên bản mới toàn lỗi 500 nhưng vẫn báo `Ready`, k8s vẫn sẽ tắt hết Pod cũ, dẫn đến 100% người dùng bị dính lỗi (Outage).

## 2. Progressive Delivery (Canary) là gì?
Canary Deployment (Lồng chim hoàng yến) là kỹ thuật chỉ điều hướng một lượng nhỏ traffic (vd: 5%) vào phiên bản mới. Sau đó quan sát các chỉ số (metrics) của phiên bản này:
- Nếu tốt: Tiếp tục tăng % traffic (lên 20%, 50%, 100%).
- Nếu có lỗi: Ngay lập tức ngắt traffic khỏi bản mới, dồn 100% traffic về bản cũ (Auto-abort / Rollback).

Điều này giúp giảm thiểu cực nhỏ bán kính ảnh hưởng (blast radius) nếu bạn lỡ deploy code lỗi ra production.

## 3. Argo Rollouts CRD
Argo Rollouts là một Kubernetes Controller, cung cấp một CRD tên là `Rollout`.
- `Rollout` thay thế hoàn toàn `Deployment`.
- Nó cung cấp các trường (fields) bổ sung để cấu hình các bước tăng dần (Steps) khi deploy.
- Tương thích tốt với Ingress Controllers (như Nginx, ALB) hoặc Service Mesh (như Istio) để tách bạch và điều hướng chính xác % traffic mong muốn.

```yaml
# Ví dụ cơ bản về Rollout CRD
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: example-rollout
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 10m} # Dừng lại 10p để lấy mẫu
      - setWeight: 50
      - pause: {duration: 10m}
```
