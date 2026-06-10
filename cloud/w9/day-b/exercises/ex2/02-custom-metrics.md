# Thực hành 2: Setup Custom Metric & Dashboard cho Ứng dụng

## Bước 1: Expose /metrics cho Counter-App
Để Prometheus cào (scrape) được dữ liệu, ứng dụng của bạn phải có một endpoint xuất ra định dạng chuẩn của Prometheus.
- Cập nhật source code của ứng dụng `Counter-App` để thêm một Prometheus Client.
- Chạy thử và đảm bảo ứng dụng có trả về dữ liệu tại đường dẫn `http://<app-ip>/metrics`.
- *Gợi ý: Nếu dùng Node.js, bạn có thể dùng thư viện `prom-client`.*

## Bước 2: Cấu hình ServiceMonitor
Trong hệ sinh thái của `kube-prometheus-stack`, cách tốt nhất để khai báo cho Prometheus biết phải cào data từ đâu là dùng `ServiceMonitor`.
1. Tạo một file `servicemonitor.yaml` cấu hình ServiceMonitor trỏ đến Label của Counter-App.
2. Apply file đó vào cụm.

## Bước 3: Tạo Dashboard Custom trên Grafana
1. Vào Grafana, tạo một Dashboard mới (New Dashboard).
2. Thêm một Panel mới.
3. Trong ô Query, viết câu PromQL đếm tổng số Request hoặc rate Request trong 5 phút qua. Ví dụ:
   ```promql
   rate(http_requests_total{app="counter-app"}[5m])
   ```
4. Lưu Dashboard lại và thử F5 ứng dụng liên tục để xem biểu đồ thay đổi.
