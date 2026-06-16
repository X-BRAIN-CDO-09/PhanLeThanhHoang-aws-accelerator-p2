# Bài tập thực hành Day 2: Secrets + Supply Chain Security

Trong phần này, bạn sẽ cấu hình YAML cho pipeline CI/CD, YAML của External Secrets, và sử dụng CLI (Cosign) để ký container image.

## Bài 1: Quản lý Secret tự động với ESO
**Mục tiêu:** Loại bỏ việc lưu secret tĩnh trong K8s, thay vào đó đồng bộ an toàn từ AWS.

**Yêu cầu:**
1. Lên AWS Secrets Manager tạo một secret (ví dụ `prod/db-password` với giá trị bất kỳ).
2. Cài đặt External Secrets Operator (ESO) vào cluster.
3. Cấu hình xác thực (IAM Roles for Service Accounts - IRSA) để ESO có quyền đọc secret từ AWS.
4. Viết file YAML `SecretStore` (cấp namespace) hoặc `ClusterSecretStore`.
5. Viết file YAML `ExternalSecret` ánh xạ secret từ AWS về một `Secret` của Kubernetes. Set `refreshInterval: 1m`.
6. **Kiểm tra:** Lên giao diện AWS thay đổi giá trị password, chờ < 60s và kiểm tra lại giá trị trong Kubernetes Secret (`kubectl get secret ... -o yaml`) xem đã được update chưa.

## Bài 2: Tích hợp Trivy Image Scanning vào CI
**Mục tiêu:** Block các image dính lỗi bảo mật nghiêm trọng ngay trong CI/CD.

**Yêu cầu:**
1. Tạo một repository mới trên GitHub/GitLab có chứa một Dockerfile (cố tình dùng một base image cũ, ví dụ `nginx:1.14`).
2. Viết file YAML cho GitHub Actions (`.github/workflows/ci.yml`) hoặc GitLab CI.
3. Trong pipeline, thêm bước build image và chạy Trivy scan.
4. Cấu hình lệnh Trivy sao cho pipeline sẽ **FAILED** nếu phát hiện ra các lỗ hổng mức độ `HIGH` hoặc `CRITICAL`.
5. Push code và quan sát pipeline thất bại.
6. Cấu hình file `trivyignore` để Accept Risk một CVE cụ thể và xem pipeline có pass không.

## Bài 3: Image Signing với Cosign
**Mục tiêu:** Chỉ cho phép chạy các image do chính bạn (hoặc pipeline của bạn) build.

**Yêu cầu:**
1. Tạo một cặp key bằng lệnh `cosign generate-key-pair`.
2. Push một image lên Docker Hub / ECR.
3. Ký image đó bằng lệnh `cosign sign --key cosign.key <image-uri>`.
4. Cài đặt Kyverno (hoặc Gatekeeper).
5. Viết một Kyverno Policy (`ClusterPolicy` dạng `verifyImages`) yêu cầu bắt buộc các image thuộc registry của bạn phải có signature hợp lệ khớp với public key `cosign.pub`.
6. **Kiểm tra:** Deploy 2 pod, một pod dùng image đã ký, một pod dùng image chưa ký, và quan sát pod chưa ký bị từ chối khởi tạo.
