# Internal Developer Platform (IDP) & Platform Integration

## 1. IDP là gì?
Internal Developer Platform (IDP) là một nền tảng nội bộ được xây dựng bởi đội ngũ Platform Engineering nhằm cung cấp trải nghiệm tự phục vụ (self-service) cho các nhà phát triển (Developers).
Mục tiêu là "trải thảm" để dev chỉ cần gõ code và commit, mọi thứ còn lại (Build, Deploy, Monitor, Security, DB provisioning) IDP sẽ tự động lo liệu, giảm tải gánh nặng cấu hình hạ tầng cho dev.

## 2. Các thành phần của một IDP tiêu chuẩn trên K8s
Một IDP (như Kube-Prometheus-Stack kết hợp GitOps mà chúng ta đang xây dựng) thường bao gồm các "lego blocks" sau:

- **Version Control & CI:** GitHub/GitLab (Lưu trữ code và tự động build image).
- **Continuous Deployment (CD):** ArgoCD hoặc Flux (Cơ chế GitOps, pull resource về cluster).
- **Secret Management:** External Secrets Operator (Kéo secret an toàn từ AWS Secrets Manager).
- **Observability (O11y):** 
  - Metrics: Prometheus + Grafana.
  - Logs: FluentBit/Promtail + Loki.
  - Traces: OpenTelemetry + Tempo/Jaeger.
- **Security & Admission:** OPA Gatekeeper / Kyverno / ValidatingAdmissionPolicy. Image scanning với Trivy, Signing với Cosign.
- **Ingress & Networking:** NGINX Ingress, Istio (Service Mesh), cert-manager (tự động cấp TLS certs).

## 3. Lợi ích của việc "Platform-ize" (GitOps-ify)
Thay vì cài tay từng thành phần bằng lệnh `helm install` (dẫn tới việc khi cluster chết là mất hết hoặc không biết cài lại thế nào), mọi config của Platform (kể cả ArgoCD) đều được khai báo bằng YAML và đẩy lên thư mục `platform-apps/` trong Git.

Mô hình **App of Apps** của ArgoCD sẽ quét thư mục đó và tự động dựng lại toàn bộ platform giống hệt bản cũ chỉ trong vài phút.

## 4. Trải nghiệm của Developer (Golden Path)
- Developer tạo PR (Pull Request).
- GitHub Actions chạy Test -> Build Image -> Scan Image (Trivy) -> Sign Image (Cosign) -> Push lên Registry.
- GitHub Actions tự động update image tag mới vào file YAML trong repository chứa config.
- ArgoCD phát hiện thay đổi trên Git repo config, tự động pull về K8s.
- K8s Policy (Kyverno) kiểm tra chữ ký image trước khi cho chạy.
- Pod khởi động, Prometheus tự động quét annotation để thu thập metric. Developer mở Grafana và thấy app đang chạy bình thường mà không cần đụng vào lệnh `kubectl` nào!
