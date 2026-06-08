# Thực hành 2: Cài đặt và cấu hình ArgoCD trên K8s

Bài tập này hướng dẫn cài đặt ArgoCD lên cluster Minikube của bạn.

## Bước 1: Cài đặt ArgoCD
Mở terminal và kết nối vào cluster K8s/Minikube. Chạy các lệnh sau:

```bash
# Tạo namespace dành riêng cho ArgoCD
kubectl create namespace argocd

# Apply bộ cài đặt chuẩn từ trang chủ của ArgoProj
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Kiểm tra xem các pod của ArgoCD đã khởi chạy thành công chưa:
```bash
kubectl get pods -n argocd
```
*(Chờ đến khi tất cả các pod có trạng thái `Running`)*

## Bước 2: Truy cập Giao diện Web ArgoCD (UI)
Theo mặc định, ArgoCD Server không expose ra public. Bạn cần port-forward để truy cập:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Bây giờ bạn có thể mở trình duyệt và truy cập: `https://localhost:8080`.
*(Lưu ý: Bỏ qua cảnh báo bảo mật SSL của trình duyệt)*

## Bước 3: Lấy mật khẩu đăng nhập
Tài khoản đăng nhập mặc định là `admin`.
Mật khẩu được ArgoCD tạo ngẫu nhiên và lưu trong một Kubernetes Secret. Mở một terminal khác và chạy lệnh sau để lấy mật khẩu:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Sử dụng mật khẩu này để đăng nhập vào trang web UI của ArgoCD.

## Bước 4: Đổi mật khẩu (Tuỳ chọn)
Sau khi đăng nhập vào UI, góc trên bên trái chọn User Info, chọn **Update Password** để đổi mật khẩu dễ nhớ hơn.

*(Sau khi đổi mật khẩu xong, bạn có thể xóa secret mật khẩu khởi tạo đi cho an toàn)*
```bash
kubectl -n argocd delete secret argocd-initial-admin-secret
```
