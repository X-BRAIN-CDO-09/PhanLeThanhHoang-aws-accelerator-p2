# Phương pháp luận SLO/SLI (Google SRE)

Theo sách SRE của Google, không có hệ thống nào đạt được 100% độ ổn định (uptime). Cố gắng đạt 100% sẽ làm giảm tốc độ phát triển tính năng và tiêu tốn cực kì nhiều tiền. Chúng ta dùng SLO để cân bằng.

## 1. SLI (Service Level Indicator)
Là **Thước đo định lượng** cho một tính chất của dịch vụ.
- Vd 1: Tỷ lệ (%) HTTP Request trả về mã 2xx hoặc 3xx.
- Vd 2: Tỷ lệ (%) HTTP Request được xử lý dưới 200ms.
Công thức chung cho SLI: `(Số sự kiện Tốt) / (Tổng số sự kiện) * 100`

## 2. SLO (Service Level Objective)
Là **Mục tiêu đặt ra** cho một SLI cụ thể.
- Vd: Hệ thống phải đạt 99.9% HTTP Request không bị lỗi trong vòng 30 ngày.
- Điều này có nghĩa: 0.1% lỗi được phép xảy ra.

## 3. SLA (Service Level Agreement)
Là **Hợp đồng ràng buộc pháp lý** với khách hàng.
- Vd: Nếu không đạt 99.9% uptime, công ty sẽ đền bù 50% tiền dịch vụ tháng đó cho khách hàng.
(Trong kỹ thuật DevOps/SRE, chúng ta tập trung vào SLI và SLO. SLA là việc của ban giám đốc và luật sư).

## 4. Error Budget (Ngân sách lỗi)
Nếu SLO của bạn là 99.9%, bạn có Error Budget là 0.1%.
- Error Budget là công cụ quyết định. Nếu còn quỹ ngân sách lỗi: Dev team được quyền release tính năng mới, thử nghiệm.
- Nếu cạn kiệt ngân sách lỗi: Đóng băng tính năng mới (Feature Freeze), tập trung 100% sức lực vào vá lỗi và tăng cường độ ổn định.

**Metrics quan trọng thường đo SLO:**
- **Availability:** Dịch vụ có đang phản hồi đúng không? (Status codes).
- **Latency:** Dịch vụ phản hồi có nhanh không? (Response time).
