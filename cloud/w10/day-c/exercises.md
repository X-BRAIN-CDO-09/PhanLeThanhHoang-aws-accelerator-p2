# Bài tập thực hành Day 3: Platform Integration + Cost

Phần này thiên về tích hợp hệ thống, tối ưu tài nguyên và xây dựng quy trình (runbook).

## Bài 1: Quản lý hạn ngạch tài nguyên (Quotas & Limits)
**Mục tiêu:** Ngăn chặn tình trạng một ứng dụng chiếm dụng toàn bộ tài nguyên của cluster (Noisy Neighbor).

**Yêu cầu:**
1. Tạo một namespace `staging`.
2. Viết YAML `ResourceQuota` giới hạn namespace này chỉ được dùng tối đa 2 CPU và 4Gi Memory, tối đa 5 Pods.
3. Viết YAML `LimitRange` quy định mọi Container tạo ra nếu không khai báo `resources`, sẽ được gán mặc định (default request: 100m CPU / 128Mi RAM, default limit: 200m CPU / 256Mi RAM).
4. **Kiểm tra:** 
   - Deploy một pod không khai resource và kiểm tra xem nó có nhận resource mặc định không.
   - Thử deploy 6 pod, hoặc 1 pod yêu cầu 3 CPU -> Hệ thống phải từ chối khởi tạo.

## Bài 2: Chaos Engineering cơ bản
**Mục tiêu:** Kiểm tra độ bền bỉ của ứng dụng khi gặp sự cố bất ngờ.

**Yêu cầu:**
1. Deploy một ứng dụng có nhiều bản sao (Deployment, `replicas: 3`). Cấu hình sẵn Readiness Probe và Liveness Probe.
2. Cài đặt Litmus Chaos hoặc Chaos Mesh.
3. Viết cấu hình Chaos Experiment (ví dụ `PodChaos`) với hành động: Cứ mỗi 30s ngẫu nhiên kill 1 pod của Deployment đó.
4. Chạy experiment và dùng lệnh `watch kubectl get pods` để quan sát K8s tự động tạo lại Pod như thế nào.

## Bài 3: Xây dựng Runbook (Tài liệu chuẩn hóa)
**Mục tiêu:** Tập viết tài liệu phản ứng sự cố theo chuẩn SRE.

**Yêu cầu:**
Tạo một file markdown `SRE-RUNBOOK.md`. Giả định tình huống giả định: **"Hệ thống GuardDuty / Security Hub báo động có một Pod trong K8s đang thực hiện kết nối ra ngoài đến một địa chỉ IP đào coin độc hại."**
Hãy soạn thảo quy trình 6 bước để xử lý:
1. **Detect:** Dấu hiệu nhận biết là gì? Xem log ở đâu?
2. **Triage:** Đánh giá mức độ nghiêm trọng.
3. **Contain:** Cách ly sự cố (đổi Security Group, NetworkPolicy, hoặc gỡ label để ngắt kết nối pod ra khỏi Service).
4. **Eradicate:** Xóa bỏ nguyên nhân (kill pod, khóa tài khoản IAM, sửa code).
5. **Recover:** Triển khai lại phiên bản sạch.
6. **Post-mortem:** Rút kinh nghiệm để không bị lại.

## Bài 4: Bật kiểm soát chi phí trên AWS
**Mục tiêu:** Cảnh báo khi chi phí tăng đột biến.

**Yêu cầu:**
1. Truy cập AWS Billing / Cost Management.
2. Thiết lập AWS Cost Anomaly Detection (hoặc AWS Budgets).
3. Đặt một mức ngân sách hoặc cảnh báo, gửi thông báo về một địa chỉ email hoặc một Slack Webhook khi chi phí dự kiến trong tháng vượt mức.
