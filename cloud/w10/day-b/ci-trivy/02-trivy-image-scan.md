# Tích hợp Trivy Image Scanning vào CI/CD

## 1. Trivy là gì?
**Trivy** (phát triển bởi Aqua Security) là một công cụ quét lỗ hổng bảo mật (vulnerability scanner) phổ biến, đơn giản và toàn diện cho container images, hệ thống tệp, Git repositories, và cả cấu hình sai (misconfiguration) của Kubernetes/Terraform.

Việc quét image trước khi deploy giúp phát hiện sớm (shift-left) các lỗ hổng của các thư viện mã nguồn mở hoặc hệ điều hành base image (như CVE-2021-44228 Log4j).

## 2. Cách sử dụng Trivy CLI
Bạn có thể dễ dàng tải Trivy và quét bất kỳ image nào trên local:
```bash
trivy image nginx:1.14
```
Lệnh này sẽ tải cơ sở dữ liệu lỗ hổng (vulnerability DB) mới nhất và xuất ra báo cáo các CVE, mức độ nghiêm trọng (LOW, MEDIUM, HIGH, CRITICAL).

## 3. Tích hợp vào CI/CD (Ví dụ: GitHub Actions)
Để ngăn chặn code có lỗi bảo mật bị push lên môi trường Production, Trivy thường được đưa vào CI pipeline như một "chốt chặn".

Ví dụ GitHub Actions Workflow:
```yaml
name: Build and Scan
on:
  push:
    branches: [ "main" ]

jobs:
  build-and-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Build an image from Dockerfile
        run: docker build -t my-app:${{ github.sha }} .

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'my-app:${{ github.sha }}'
          format: 'table'
          # Chỉ báo lỗi và FAIL pipeline nếu mức độ là HIGH hoặc CRITICAL
          exit-code: '1'
          severity: 'CRITICAL,HIGH'
```
Trong ví dụ này:
- `exit-code: '1'` làm pipeline thất bại ngay lập tức nếu tìm thấy lỗi.
- `severity: 'CRITICAL,HIGH'` bộ lọc để bỏ qua các lỗi LOW, MEDIUM.

## 4. Bỏ qua lỗ hổng chấp nhận được (.trivyignore)
Thực tế, có những lỗi `HIGH` nhưng không ảnh hưởng tới logic của bạn hoặc chưa có bản vá từ nhà cung cấp. Thay vì để CI luôn đỏ, bạn tạo một file tên là `.trivyignore` ở thư mục gốc của project chứa ID của CVE:

```
# .trivyignore
CVE-2023-12345
CVE-2022-98765
```
Khi chạy, Trivy sẽ bỏ qua các CVE này và CI của bạn có thể pass thành công.
