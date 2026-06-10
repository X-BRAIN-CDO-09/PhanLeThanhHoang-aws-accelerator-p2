# Thực hành 3: Định nghĩa SLO và Alerting Burn Rate

## Bước 1: Tính toán SLI bằng PromQL
Viết một câu PromQL để tính **Tỷ lệ lỗi (Error Rate)** hoặc **Độ trễ (Latency)** của ứng dụng.
- Ví dụ SLI cho tỷ lệ lỗi: Số request trả về HTTP 5xx chia cho Tổng số request.
- Định nghĩa SLO của bạn: Ví dụ, "Ứng dụng phải có độ khả dụng 99% trong vòng 30 ngày".

## Bước 2: Thiết lập PrometheusRule (Cảnh báo Alert)
Thay vì cảnh báo truyền thống (lỗi cái báo ngay), chúng ta áp dụng mô hình **Multi-window burn rate alert** theo chuẩn SRE.

1. Viết cấu hình `PrometheusRule` CRD (hoặc cấu hình trực tiếp Alert trong Grafana).
2. Cấu hình báo động nếu Error Budget bị tiêu thụ quá nhanh (Burn Rate > 14.4 trong 1 giờ).

## Bước 3: Kiểm thử Báo động (Alert Firing)
1. Hãy "phá" ứng dụng của bạn: Gửi hàng loạt request lỗi (ví dụ gọi API với tham số sai) để tỷ lệ lỗi tăng vọt.
2. Mở giao diện AlertManager (có thể port-forward dịch vụ `monitoring-kube-prometheus-alertmanager` ra port `9093`).
3. Quan sát xem Alert của bạn có chuyển từ trạng thái `Pending` sang `Firing` hay không.
