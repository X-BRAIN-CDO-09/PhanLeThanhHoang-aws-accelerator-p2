# Kiểm soát chi phí AWS và Kubernetes

## 1. Vấn đề chi phí đám mây (Cloud Bill Shock)
Hạ tầng Cloud rất dễ mở rộng. Một vòng lặp vô hạn sinh log có thể ngốn hàng trăm đô tiền CloudWatch, hoặc một cấu hình Auto-scaling lỗi có thể tự bật hàng chục máy EC2. Nếu đợi đến cuối tháng mới xem hóa đơn, bạn sẽ phải trả giá đắt (Cloud bill shock).

## 2. Công cụ kiểm soát của AWS

### AWS Cost Anomaly Detection
Dịch vụ này sử dụng Machine Learning để phân tích xu hướng tiêu dùng lịch sử của bạn và phát hiện những đợt tăng chi phí bất thường (Anomaly).
- **Cách dùng:** Truy cập Billing Console -> Cost Anomaly Detection -> Tạo Monitor theo Subscriptions (gửi về Email hoặc Slack SNS topic).
- **Lợi ích:** Không cần đoán trước hạn mức ngân sách, AWS tự báo nếu chi phí vọt lên một cách vô lý.

### AWS Budgets
Cho phép bạn đặt một con số ngân sách cụ thể (Ví dụ: $100/tháng).
- **Alert:** Khi số tiền ĐÃ DÙNG hoặc DỰ KIẾN (Forecast) vượt 80% hoặc 100% mức $100, hệ thống sẽ bắn email cảnh báo.
- **Action (Nâng cao):** Có thể cấu hình tự động stop EC2 instance hoặc từ chối cấp quyền tạo tài nguyên mới nếu vượt ngân sách.

## 3. Kiểm soát chi phí nội bộ Kubernetes (Kubecost / OpenCost)
AWS báo giá theo mức hạ tầng vật lý (EC2, EBS). Nhưng trong EKS cluster, làm sao biết namespace của đội Frontend hay đội Backend xài tốn tiền hơn?

**Kubecost (hoặc OpenCost)** là công cụ sinh ra để giải quyết bài toán này:
- Nó đọc thông tin CPU/RAM Requests và Limits từ K8s, đối chiếu với giá tiền thực tế của EC2 trên AWS (có tính toán Spot vs On-Demand).
- Hiển thị Dashboard cho thấy: Namespace `frontend` tốn $50/tháng, Namespace `backend` tốn $150/tháng.
- Đưa ra khuyến nghị (Right-sizing): "Pod này xin 4 core CPU nhưng chỉ dùng có 0.1 core, hãy giảm request xuống để tiết kiệm $30/tháng".

## 4. Best Practices tối ưu chi phí
- Gắn **Tag** (ví dụ: `Environment=Prod`, `Team=Data`) cho tất cả tài nguyên AWS ngay từ khi viết Terraform. Kích hoạt Cost Allocation Tags để xem chi phí theo team.
- Dùng Spot Instances cho các workload có tính toán theo mẻ (Batch processing) hoặc các K8s Pods có thể bị kill không thương tiếc (Stateless web server).
- Bật vòng đời xóa log (Log Retention) cho CloudWatch Logs (mặc định log lưu vĩnh viễn rất tốn tiền).
- Áp dụng chặt chẽ K8s ResourceQuota để giới hạn tài nguyên các namespace Development/Staging.
