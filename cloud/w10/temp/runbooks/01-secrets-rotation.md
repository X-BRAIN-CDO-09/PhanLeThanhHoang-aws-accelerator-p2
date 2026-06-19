# Runbook 01: Secrets Rotation với ESO

## 1. Mục đích
Hướng dẫn cách xoay vòng (rotate) mật khẩu an toàn và cách xử lý sự cố khi cấu hình External Secrets Operator (ESO) không đồng bộ.

## 2. Quy trình Xoay vòng Mật khẩu
1. Đăng nhập vào giao diện **AWS Secrets Manager**.
2. Tìm đến secret tương ứng (ví dụ: `demo/db/password`).
3. Cập nhật `Secret value` mới và lưu lại.
4. **Không cần** khởi động lại (restart) Pod trong Cluster. Kể từ lúc lưu trên AWS, ESO sẽ tự động kiểm tra định kỳ (theo `refreshInterval`, mặc định < 60s) và đồng bộ giá trị mới xuống Kubernetes Secret.
5. Volume chứa Secret trong Pod sẽ tự động cập nhật file. Ứng dụng (nếu hỗ trợ hot-reload) sẽ đọc mật khẩu mới.

## 3. Khắc phục sự cố (Troubleshooting)
**Sự cố:** Cập nhật mật khẩu trên AWS nhưng sau 2 phút Pod vẫn không nhận giá trị mới.
**Cách xử lý:**
1. Kiểm tra trạng thái của ExternalSecret:
   ```bash
   kubectl get externalsecret -n <namespace>
   ```
   *Kết quả mong đợi: Cột `READY` là `True`.*
2. Nếu `READY` là `False`, xem chi tiết lỗi:
   ```bash
   kubectl describe externalsecret <tên-secret> -n <namespace>
   ```
   *Nguyên nhân thường gặp: Lỗi IAM Role (không có quyền đọc AWS), hoặc sai tên `SecretStore`, hoặc sai đường dẫn `remoteRef`.*
3. Đảm bảo SecretStore cấu hình đúng:
   ```bash
   kubectl get secretstore -n <namespace>
   ```
