# Thực hành 4: Tích hợp OpenTelemetry (OTel) và Loki Logging

## Bước 1: Cài đặt OpenTelemetry Collector
1. Cài đặt OTel Collector vào Kubernetes cluster của bạn thông qua Helm chart của OpenTelemetry.
2. Cấu hình OTel Collector để nhận traces và metrics từ ứng dụng.

## Bước 2: Instrumentation cho Counter-App
Sử dụng OTel SDK (hoặc cơ chế Auto-Instrumentation nếu dùng Java/Node.js) để gửi Traces và Metrics từ Counter-App về OTel Collector.
- Cấu hình endpoint của OTel Collector trong biến môi trường của Counter-App.

## Bước 3: Tích hợp Grafana Loki (Quản lý Log)
1. Cài đặt Promtail và Loki (bằng Helm) vào cluster.
2. Promtail sẽ cào toàn bộ Log của các Pod trong K8s và gửi về Loki.
3. Mở Grafana, vào phần Data Sources, thêm Data Source là Loki.
4. Sử dụng tính năng **Explore** trên Grafana, chọn Loki và tìm kiếm log của ứng dụng Counter-App bằng LogQL:
   ```logql
   {app="counter-app"} |= "error"
   ```

## Hoàn thiện
Hãy kết hợp cả Metric, Trace, và Log lên cùng một Dashboard để tạo thành bộ 3 trụ cột (Three Pillars) hoàn chỉnh của Observability!
