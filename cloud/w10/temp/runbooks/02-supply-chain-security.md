# Runbook 02: Xử lý Supply Chain Security (Trivy & Cosign)

## 1. Mục đích
Cung cấp các bước xử lý khi luồng triển khai CI/CD bị chặn do lỗi bảo mật từ Trivy hoặc lỗi thiếu chữ ký (Signature) từ Cosign.

## 2. Xử lý khi Trivy Scan báo lỗi (CI Đỏ)
**Tình huống:** GitHub Actions bị báo lỗi (failed) ở bước Trivy scan với thông báo phát hiện CVE `HIGH` hoặc `CRITICAL`.
**Cách xử lý:**
1. Mở log của GitHub Actions, tìm đọc danh sách các CVE bị đánh dấu `HIGH` hoặc `CRITICAL`.
2. Kiểm tra cột `FIXED VERSION` trong log của Trivy.
   - **Nếu ĐÃ có bản vá (Fixed Version):** Cập nhật `Dockerfile` để sử dụng base image phiên bản mới nhất, hoặc nâng cấp thư viện bị lỗi. Sau đó commit và push lại.
   - **Nếu CHƯA có bản vá:** Lỗi thuộc về nhà phát hành gốc và chưa có cách sửa chữa. Chuyển sang bước viết **Exception ADR** (Xem file `adr-001-cve-exception.md`) để cho phép ngoại lệ tạm thời. Cập nhật cấu hình Trivy (`trivy-ignore`) nếu ADR được phê duyệt.

## 3. Xử lý khi Admission Controller từ chối Image
**Tình huống:** Kube-api server từ chối tạo Pod với thông báo: `admission webhook denied the request: no matching signatures`.
**Cách xử lý:**
1. Lỗi này nghĩa là Image bạn đang cố deploy chưa được ký (sign) bằng Cosign, hoặc chữ ký không khớp với Public Key trên Cluster.
2. Đảm bảo Image được push qua luồng CI chính thức (GitHub Actions) để tự động kích hoạt tiến trình `cosign sign`.
3. Kiểm tra xem image tag đó đã có file `.sig` đi kèm trên Container Registry chưa:
   ```bash
   cosign verify --key signing/cosign.pub <your-image-url>:<tag>
   ```
4. Nếu chưa ký, bạn có thể ký thủ công bằng lệnh (nếu có quyền giữ Private Key):
   ```bash
   cosign sign --key cosign.key <your-image-url>:<tag>
   ```
