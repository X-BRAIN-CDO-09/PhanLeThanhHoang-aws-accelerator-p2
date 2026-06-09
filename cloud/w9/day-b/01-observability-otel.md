# OpenTelemetry (OTel): SDK và Collector

## 1. OpenTelemetry là gì?
OpenTelemetry (OTel) là một dự án của CNCF, cung cấp một chuẩn chung để thu thập và xuất (export) các dữ liệu Telemetry:
- **Metrics:** Số đo tại một thời điểm (vd: CPU usage, Số lượng HTTP Requests).
- **Logs:** Thông báo văn bản được sinh ra (vd: "User logged in").
- **Traces:** Ghi nhận vòng đời của một request đi qua nhiều microservices.

Trước OTel, lập trình viên phải phụ thuộc vào các thư viện riêng rẽ cho từng vendor (Prometheus cho metrics, Fluentd cho logs, Jaeger cho traces). Với OTel, bạn viết code một lần (instrumentation), và có thể gửi data đến bất kỳ backend nào.

## 2. OTel SDK và Instrumentation
Có 2 cách để gắn OTel vào ứng dụng của bạn:
- **Auto-instrumentation:** Sử dụng các agent tự động gắn vào runtime (Java Agent, Python Agent, Node.js auto-require). Agent tự bắt các lời gọi HTTP, Database mà không cần sửa code.
- **Manual-instrumentation (SDK):** Lập trình viên trực tiếp sử dụng OTel SDK trong source code để tạo ra các custom span (trace) hoặc custom metric đếm số lượng người dùng cụ thể.

## 3. OTel Collector
OTel Collector là một proxy nằm giữa Ứng dụng và Backend lưu trữ (như Prometheus, Jaeger). 

**Kiến trúc Collector bao gồm:**
- **Receivers:** Nhận data từ các ứng dụng đẩy tới (qua giao thức OTLP, Jaeger, Zipkin...).
- **Processors:** Xử lý data (lọc bớt log thừa, batching, đổi tên thẻ/tags...).
- **Exporters:** Gửi data đến các backend đích (Prometheus, Grafana Cloud, Datadog...).

Sử dụng OTel Collector giúp ứng dụng nhẹ hơn, giảm số lần retry/timeout gửi dữ liệu, và cho phép thay đổi backend monitor mà không cần chạm vào code ứng dụng.
