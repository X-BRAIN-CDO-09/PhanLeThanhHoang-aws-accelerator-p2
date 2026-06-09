# Bài tập Day B: Observability Practice

## Yêu cầu

### 1. Cài đặt kube-prometheus-stack
Sử dụng Helm để cài đặt `kube-prometheus-stack` (đã bao gồm Prometheus, Grafana, AlertManager) vào cluster của bạn.
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

### 2. Cấu hình Data Source và xem Dashboard cơ bản
1. Port-forward Grafana (`svc/monitoring-grafana`) ra localhost:3000.
2. Đăng nhập bằng tài khoản mặc định `admin` / `prom-operator`.
3. Truy cập vào mục Dashboards -> Khám phá một số dashboard có sẵn (như Node Exporter, Kubernetes Compute Resources).
4. Quan sát các thông số CPU/RAM của cluster.

### 3. Setup Custom Metric & Dashboard cho Counter-App
1. Deploy một phiên bản của `counter-app` (ứng dụng W8) mà có sinh ra metrics ở endpoint `/metrics`. (Nếu app cũ chưa có, hãy code thêm 1 đoạn Prometheus client nhỏ để expose `/metrics`).
2. Cấu hình `ServiceMonitor` CRD để Prometheus cào (scrape) metric từ Counter-App.
3. Vào Grafana, tạo một Dashboard mới. Viết câu query PromQL đếm số lượng Request (ví dụ: `rate(http_requests_total[5m])`).

### 4. Định nghĩa SLO và Alerting
1. Tính SLI: Viết một câu PromQL để tính tỷ lệ lỗi HTTP 5xx của ứng dụng.
2. Thiết lập một Rule trong `PrometheusRule` CRD (hoặc cấu hình trực tiếp Alert trong Grafana) báo động nếu tỷ lệ lỗi vượt quá 5% trong vòng 1 phút.
3. Gửi vài request làm ứng dụng sinh lỗi, sau đó quan sát Alert chuyển sang trạng thái "Firing".
