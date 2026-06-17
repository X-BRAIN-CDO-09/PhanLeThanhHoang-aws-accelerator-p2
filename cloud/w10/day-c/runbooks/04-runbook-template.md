# Xây dựng SRE Runbook (Tài liệu chuẩn hóa sự cố)

## 1. Runbook là gì?
Runbook (hay Playbook) là tài liệu hướng dẫn từng bước cụ thể để một kỹ sư trực (On-call Engineer) xử lý một sự cố cụ thể khi nhận được cảnh báo (Alert). Một Runbook tốt giúp kỹ sư mới cũng có thể nhanh chóng khắc phục lỗi mà không cần gọi người viết code dậy giữa đêm.

## 2. Cấu trúc chuẩn của một quá trình ứng phó sự cố (Incident Response)
Quá trình xử lý thường đi theo 6 bước: **Detect -> Triage -> Contain -> Eradicate -> Recover -> Post-mortem**.

### [Mẫu Runbook] Sự cố: K8s Pod đào coin (Cryptomining) kết nối ra ngoài

**A. Detect (Phát hiện)**
- **Dấu hiệu:** Alert từ AWS Security Hub hoặc GuardDuty thông báo: "EC2 instance / K8s Pod communicating with known cryptomining pool". Alert từ Prometheus: CPU tăng đột biến 100%.
- **Nơi kiểm tra:** Mở GuardDuty Console, Mở Grafana Dashboard CPU usage. Chạy lệnh `kubectl top pods -A`.

**B. Triage (Đánh giá & Phân loại)**
- **Mức độ:** CRITICAL (Nghiêm trọng). Việc này tốn tiền hạ tầng rất nhanh và có rủi ro lộ lọt dữ liệu.
- **Xác định thủ phạm:** `kubectl logs <tên-pod>`. Dùng lệnh `kubectl describe pod <tên-pod>` để xem image nào đang được sử dụng.

**C. Contain (Cách ly - CẦM MÁU)**
*Mục tiêu: Ngăn chặn mã độc lan rộng hoặc tiếp tục phá hoại trước khi tìm ra nguyên nhân gốc.*
- Tách Pod khỏi Load Balancer/Service bằng cách xóa label của pod đó: `kubectl label pod <tên-pod> app-`
- Hoặc áp dụng NetworkPolicy "Deny All Egress" lên namespace bị nhiễm để cắt kết nối mạng ra internet của pod đào coin.
- Tạm thời khóa quyền IAM của Worker Node nếu nghi ngờ bị đánh cắp credential.

**D. Eradicate (Triệt tiêu nguyên nhân)**
- Xóa Pod chứa mã độc: `kubectl delete pod <tên-pod>` (Nếu deployment tự tạo lại, scale deployment về 0: `kubectl scale deployment <tên-deploy> --replicas=0`).
- Chặn image độc hại bằng cách cập nhật Gatekeeper/Kyverno policy. Xóa image khỏi Registry.

**E. Recover (Phục hồi)**
- Deploy lại ứng dụng bằng image cũ (đã biết là an toàn) hoặc fix lỗ hổng (ví dụ cập nhật thư viện bị dính RCE) và push image mới.
- Mở lại NetworkPolicy và khôi phục hoạt động bình thường.

**F. Post-mortem (Phân tích sau sự cố)**
- Làm thế nào mã độc vào được container? (Do developer dùng base image không rõ nguồn gốc hay do thư viện npm/pip bị hack?).
- Hành động cải thiện: Bắt buộc bật Trivy scan chặn image có lỗi High/Critical trên CI/CD. Bắt buộc bật Image Signing.
