# Nền tảng Observability: Prometheus + Grafana + Loki

Một "Ngôi nhà" Observability cơ bản trong K8s thường có 3 thành phần (LGTM stack version rút gọn):

## 1. Prometheus (Metrics)
Prometheus là Time-Series Database (TSDB) theo cơ chế **Pull**.
- Nhiệm vụ: Kéo (scrape) các thông số metric định kỳ (thường 15s/lần) từ các ứng dụng và các exporter (Node Exporter, Kube-state-metrics).
- Cung cấp ngôn ngữ truy vấn cực kì mạnh mẽ tên là PromQL (Prometheus Query Language) để tính toán trung bình, tổng lượng request, tỷ lệ lỗi (Error Rate).

## 2. Loki (Logs)
Loki là hệ thống lưu trữ log do Grafana Labs phát triển, được thiết kế giống với Prometheus nhưng dành cho log.
- Nhiệm vụ: Lưu trữ log của tất cả các Pod trong cụm Kubernetes.
- Điểm khác biệt: Loki không đánh chỉ mục (index) toàn bộ nội dung text của log (như Elasticsearch làm), mà chỉ index các Metadata (Tags/Labels) giống như Prometheus. Vì vậy nó rất nhẹ và tốn ít chi phí.
- Truy vấn: Bằng ngôn ngữ LogQL (rất giống PromQL).

## 3. Grafana (Dashboard)
Grafana là phần mềm giao diện (UI) mạnh mẽ nhất hiện nay để trực quan hóa dữ liệu.
- Nhiệm vụ: Nối vào các nguồn dữ liệu (Data Sources) như Prometheus và Loki.
- Lấy kết quả từ các truy vấn PromQL/LogQL và vẽ lên các biểu đồ (Graphs, Gauges, Heatmaps).
- Cung cấp khả năng Alerting mạnh mẽ và quản lý Dashboard dưới dạng JSON (rất tiện để quản lý bằng GitOps).

**Tóm tắt luồng hoạt động:**
Ứng dụng sinh ra số liệu -> Prometheus kéo về lưu lại -> Grafana truy vấn Prometheus -> Vẽ biểu đồ lên màn hình.
