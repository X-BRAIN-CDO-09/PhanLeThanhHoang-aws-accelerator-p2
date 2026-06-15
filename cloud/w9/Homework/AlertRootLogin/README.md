# Hướng Dẫn Thực Hành: Alert on AWS Root Account Login

Bài hướng dẫn này giúp bạn thiết lập cảnh báo khi có người đăng nhập bằng tài khoản Root trên AWS, theo yêu cầu của bài tập.

---

## I. Triển khai tài nguyên (Sử dụng Terraform)

1. Mở terminal tại thư mục này và chạy lệnh khởi tạo:
   ```bash
   terraform init
   ```
2. Xem trước các thay đổi:
   ```bash
   terraform plan
   ```
3. Triển khai tài nguyên:
   ```bash
   terraform apply
   ```
   (Gõ `yes` khi được hỏi).
4. **Rất quan trọng**: Sau khi Terraform chạy xong, hãy kiểm tra hộp thư email `hoangk5fc5@gmail.com`. Bạn sẽ nhận được một email từ AWS Notifications. Hãy click vào đường link **Confirm subscription** trong email đó để bắt đầu nhận cảnh báo.

---

## II. Hướng dẫn chụp ảnh minh chứng (Evidence Guide)

Để chứng minh bạn đã hoàn thành bài tập, hãy thực hiện chụp màn hình các giao diện sau (trên AWS Console hoặc Email) và lưu vào thư mục `assets/`, sau đó dán vào file **`EVIDENCE.md`**.

1. **Evidence 1: CloudTrail đã tích hợp CloudWatch Logs**
   - Truy cập **CloudTrail** -> Chọn **Trails** bên thanh điều hướng -> Nhấp vào trail có tên `root-login-alert-trail`.
   - Chụp màn hình để thấy phần **CloudWatch Logs** đã được Enabled và trỏ tới Log group (VD: `/aws/cloudtrail/root-login-alert-logs`). Lưu tên file là `cloudtrail_config.png` trong folder `assets/` (nếu muốn đường dẫn có sẵn hoạt động ngay).

2. **Evidence 2: CloudWatch Metric Filter chính xác**
   - Truy cập **CloudWatch** -> **Logs** -> **Log groups**.
   - Mở log group của CloudTrail, chuyển sang tab **Metric filters**.
   - Chụp màn hình cho thấy bộ lọc có tên `RootAccountLoginFilter` cùng với Filter pattern: `{ $.userIdentity.type = "Root" && $.eventType != "AwsServiceEvent" }`. Lưu là `metric_filter.png`.

3. **Evidence 3: CloudWatch Alarm & Cấu hình SNS**
   - Truy cập **CloudWatch** -> **Alarms** -> **All alarms**.
   - Nhấp vào Alarm mang tên `Alert-Root-Login`.
   - Chụp màn hình tổng quan chi tiết của Alarm, kéo xuống để lấy được phần **Conditions** và **Actions**. Lưu là `alarm_config.png`.

4. **Evidence 4: Xác nhận Email (SNS Subscription)**
   - Mở hộp thư email của bạn (`hoangk5fc5@gmail.com`).
   - Chụp lại màn hình email từ AWS có thông báo **Subscription Confirmation**. Lưu là `sns_confirmation.png`.

5. **Evidence 5 (Thực tế): Nhận Email Cảnh Báo khi đăng nhập Root**
   - Thử đăng xuất và đăng nhập lại vào AWS Console bằng **tài khoản Root**.
   - Đợi khoảng 5-10 phút để hệ thống ghi nhận log và kích hoạt Alarm.
   - Chụp lại email nhận được với dòng chữ **ALARM: "Alert-Root-Login"**. Lưu là `alert_email.png`.

*(Sau khi hoàn thiện xong file `EVIDENCE.md`, bạn có thể xoá file `README.md` này đi cho gọn thư mục dự án).*
