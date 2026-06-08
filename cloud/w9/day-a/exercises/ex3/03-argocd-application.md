# Thực hành 3: Triển khai Ứng dụng bằng GitOps (ArgoCD Application)

Ở bài tập này, chúng ta sẽ bắt ArgoCD theo dõi kho lưu trữ Git và tự động apply code Kubernetes (Deployment, Service) của Counter-App.

## Bước 1: Dọn dẹp ứng dụng cũ (nếu có)
Nếu tuần trước bạn đã cài Counter-App bằng lệnh `kubectl apply -f ...` thủ công, hãy xóa chúng đi để ArgoCD có thể quản lý từ đầu một cách sạch sẽ:
```bash
kubectl delete deployment counter-app
kubectl delete svc counter-app-service
```

## Bước 2: Tạo manifest ArgoCD Application
Tạo một file có tên `counter-app-argocd.yaml` trên máy của bạn (có thể lưu ở mục `cloud/w9/day-a/exercises/`) với nội dung sau:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: counter-app-gitops
  namespace: argocd
spec:
  project: default
  source:
    # URL của kho lưu trữ git chứa mã nguồn (thay bằng URL repo của bạn)
    repoURL: 'https://github.com/hoang/my-aws-accelerator-repo.git'
    # Thư mục chứa các file yaml (deployment.yaml, service.yaml) của counter-app
    path: 'cloud/week-project/Counter-App/kubernetes' 
    # Nhánh muốn theo dõi
    targetRevision: HEAD
  destination:
    # Cluster đích (trong trường hợp này là cluster đang chứa ArgoCD)
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    # Bật tính năng tự động đồng bộ (Auto-Sync)
    automated:
      prune: true     # Xoá resources nếu bị xoá khỏi Git
      selfHeal: true  # Tự động đè lại nếu có ai dùng kubectl sửa code thủ công trên cluster
```

*(Hãy chắc chắn bạn sửa lại `repoURL` và `path` cho đúng với repository của bạn).*

## Bước 3: Apply Application vào K8s
Chạy lệnh apply file khai báo ArgoCD Application:

```bash
kubectl apply -f counter-app-argocd.yaml
```

## Bước 4: Quan sát điều kì diệu
1. Mở giao diện ArgoCD UI (`https://localhost:8080`).
2. Bạn sẽ thấy một "App" mới xuất hiện tên là `counter-app-gitops`.
3. Bấm vào đó, bạn sẽ thấy sơ đồ mạng nhện biểu diễn toàn bộ các tài nguyên (Deployment, ReplicaSet, Pods, Service) đang được tự động sinh ra.
4. Trạng thái sẽ báo `Healthy` và `Synced`.

## Bước 5: Kiểm thử luồng GitOps
1. Trong file `deployment.yaml` của `counter-app` trên Git, hãy thử đổi số `replicas` từ `1` thành `3`.
2. Commit và Push thay đổi lên Git.
3. Chờ tối đa 3 phút (hoặc bấm nút `Refresh` trên ArgoCD UI). 
4. Quan sát số Pod tự động scale lên thành 3 mà không cần bạn chạy bất kỳ lệnh `kubectl` nào!
