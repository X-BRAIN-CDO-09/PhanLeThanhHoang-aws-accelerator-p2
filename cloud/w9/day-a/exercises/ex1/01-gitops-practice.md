# Bài tập Day A: GitOps & CI/CD Practice

## Yêu cầu

### 1. Cấu hình GitHub Actions cho Terraform (CI/CD)
1. Trong repository của bạn, tạo file `.github/workflows/tf-plan.yml` cấu hình để:
   - Kích hoạt khi có Pull Request thay đổi thư mục `terraform/`
   - Chạy lệnh `terraform fmt -check`, `terraform init`, và `terraform plan`
2. Tạo file `.github/workflows/tf-apply.yml` cấu hình để:
   - Kích hoạt khi code được merge vào nhánh `main` (push to `main`).
   - Tự động chạy `terraform apply -auto-approve`.

### 2. Cài đặt và cấu hình ArgoCD
1. Sử dụng Minikube đã setup từ tuần 8, cài đặt ArgoCD vào namespace `argocd`.
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
2. Port-forward ArgoCD Server để truy cập qua Localhost. Lấy password mặc định của admin.

### 3. Cấu hình ứng dụng GitOps (Counter-App)
1. Xóa các resources cũ của Counter-App đã deploy thủ công từ W8.
2. Viết file `counter-app-argocd.yaml` (kind: `Application`) chỉ định repository chứa file Kubernetes Manifests của Counter App.
3. Apply file `counter-app-argocd.yaml` vào cụm. Lên giao diện ArgoCD theo dõi quá trình Sync tự động.
4. Thử thay đổi tag image của app trên Git (thành một version khác, vd: từ `v1` sang `v2`). Đẩy code lên. Quan sát ArgoCD tự động detect và cập nhật hệ thống.

### 4. Kiểm thử Rollback
1. Thử cố ý sửa image tag thành một phiên bản lỗi (vd: `my-app:non-exist`).
2. Quan sát ArgoCD deploy ra Pod lỗi (CrashLoopBackOff hoặc ErrImagePull).
3. Thực hiện quá trình `git revert` để xem ArgoCD có tự động sửa sai hay không. Mất bao lâu để hệ thống phục hồi? Ghi chú lại kết quả.
