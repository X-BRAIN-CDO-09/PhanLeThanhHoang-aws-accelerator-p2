# Cảnh báo Burn Rate Đa khung giờ (Multi-window Burn Rate Alert)

Khi sử dụng SLO và Error Budget, câu hỏi đặt ra là: **Khi nào thì nên gọi người dậy lúc 2h sáng (Pager/Alert) để xử lý lỗi?**

Nếu chỉ tạo alert kiểu "Tỷ lệ lỗi > 5% trong 1 phút", nó sẽ spam báo động vì mạng đôi khi chập chờn một chút là bình thường. Nếu alert kiểu "Error Budget còn < 10% trong 30 ngày", thì đợi lúc nhận cảnh báo là hệ thống đã sập được 1 tuần rồi.

Giải pháp của Google là: **Burn Rate Alerting**.

## 1. Burn Rate là gì?
Tốc độ đốt ngân sách lỗi (Error Budget). 
- Burn rate = 1 : Nghĩa là đúng 30 ngày bạn sẽ dùng hết 100% ngân sách lỗi. Mức này là hoàn hảo.
- Burn rate = 10 : Bạn đang đốt ngân sách nhanh gấp 10 lần mức cho phép. Tức là chỉ 3 ngày sẽ hết ngân sách.
- Burn rate = 1000: Có một Incident rất lớn, ngân sách lỗi tháng này sẽ bay hơi trong vòng chưa tới 1 tiếng.

## 2. Tại sao cần Multi-window (Đa khung giờ)?
Google khuyên dùng nhiều cửa sổ thời gian kết hợp để tránh False Positives (Báo động giả):
- Cửa sổ ngắn (vd: 5 phút) để phát hiện tốc độ lỗi hiện tại.
- Cửa sổ dài (vd: 1 giờ) để đảm bảo lỗi đang diễn ra một cách liên tục, không phải chỉ là 1 chớp nhoáng (spike).

## 3. Setup chuẩn
- **Fast Alert (Trực tiếp réo điện thoại - Pager/Critical):** 
  - Điều kiện: Burn Rate > 14.4 trong cả [khung 1h] VÀ [khung 5m].
  - Ý nghĩa: Ngân sách đang bị đốt rất nhanh (mất 2% budget chỉ trong 1 giờ). Cần fix ngay.
- **Slow Alert (Chỉ gửi email hoặc tin nhắn Slack - Warning/Ticket):**
  - Điều kiện: Burn Rate > 6 trong cả [khung 6h] VÀ [khung 30m].
  - Ý nghĩa: Hệ thống có vấn đề rỉ rả (leak, lỗi nhẹ). Sẽ cạn budget trong vài ngày. Cần xem lại trong giờ hành chính.

Cách này giúp SRE có giấc ngủ ngon, chỉ thức dậy khi có chuyện thực sự nghiêm trọng đe dọa đến SLO.
