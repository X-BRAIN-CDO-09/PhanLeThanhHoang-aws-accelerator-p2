# ArgoCD Advanced: App-of-Apps và Sync Waves

## 1. Mẫu App-of-Apps Pattern
Khi bạn có hàng chục hoặc hàng trăm application trên Kubernetes (vd: CoreDNS, Ingress Controller, Cert Manager, Prometheus, cùng các Microservices), việc tạo thủ công từng ứng dụng (Application CRD) trên ArgoCD không còn khả thi. 

Giải pháp là pattern **App of Apps**:
- Chúng ta tạo ra 1 "Root Application" (App mẹ) trong ArgoCD.
- Trạng thái cấu hình của App mẹ này trỏ tới một thư mục Git chứa các `Application` manifests con.
- Khi ArgoCD sync App mẹ, nó sẽ tự động phát hiện và sinh ra (deploy) tất cả các App con.
- Nhờ vậy, muốn thêm một tool/ứng dụng mới vào cluster, bạn chỉ cần tạo một file manifest của Argo Application và push lên Git. ArgoCD sẽ lo phần còn lại.

```yaml
# Ví dụ Root Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/my-org/gitops-repo.git'
    path: apps/
    targetRevision: HEAD
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
```

## 2. Sync Waves và Sync Hooks
Khi triển khai hàng loạt dịch vụ, thứ tự khởi tạo rất quan trọng. Ví dụ: bạn phải cài Namespace trước, cài Ingress Controller sau, rồi mới cài các Backend API.

**Sync Waves** giúp bạn quy định thứ tự các tài nguyên được ArgoCD triển khai:
- Các tài nguyên có số wave nhỏ (vd: `-1`, `0`) được sync trước.
- Các tài nguyên có số wave lớn (vd: `1`, `2`) được sync sau, và *chỉ khi* wave trước đó đã vào trạng thái Healthy.

Khai báo wave qua Annotation trong manifest:
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "5"
```

**Sync Hooks** cho phép bạn chạy các tác vụ đặc thù (như chạy Database Migration Job) tại các giai đoạn của quá trình sync:
- `PreSync`: Chạy trước khi apply manifests.
- `Sync`: Chạy song song với apply manifests.
- `PostSync`: Chạy sau khi apply xong.

Kết hợp Sync Waves và App-of-Apps tạo ra trải nghiệm bootstrapping cluster "1-click" hoàn hảo.
