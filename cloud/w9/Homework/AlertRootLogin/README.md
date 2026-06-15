# AWS Root Account Login Alert

## Description
Dự án này tự động hoá việc thiết lập hệ thống cảnh báo khi có người đăng nhập vào tài khoản Root trên AWS thông qua Infrastructure as Code (Terraform). Hệ thống giám sát các sự kiện đăng nhập trên AWS Console và gửi email thông báo mỗi khi tài khoản Root được sử dụng, tuân thủ các best practice về bảo mật của AWS.

## Architecture & Resources
Các tài nguyên AWS được khởi tạo bao gồm:
- **AWS CloudTrail**: Ghi lại các API call và management events trên tài khoản.
- **Amazon CloudWatch Logs**: Lưu trữ và giám sát logs từ CloudTrail.
- **CloudWatch Metric Filter**: Lọc các logs sự kiện đăng nhập của tài khoản Root (`{ $.userIdentity.type = "Root" && $.eventType != "AwsServiceEvent" }`).
- **Amazon CloudWatch Alarm**: Kích hoạt cảnh báo khi metric filter phát hiện có lượt đăng nhập từ tài khoản Root.
- **Amazon SNS (Simple Notification Service)**: Gửi email thông báo đến địa chỉ đã được cấu hình khi Alarm bị kích hoạt.

## Prerequisites
- Đã cài đặt Terraform.
- Đã cấu hình AWS CLI với credentials có đủ quyền để tạo các tài nguyên trên.

## Usage

1. Khởi tạo Terraform:
   ```bash
   terraform init
   ```
2. Kiểm tra kế hoạch triển khai (plan):
   ```bash
   terraform plan
   ```
3. Triển khai tài nguyên:
   ```bash
   terraform apply
   ```
   *(Gõ `yes` khi được yêu cầu xác nhận)*

4. **Xác nhận SNS Subscription**: Rất quan trọng, sau khi Terraform chạy xong, hãy kiểm tra hộp thư email được cấu hình và click vào **Confirm subscription** trong email từ AWS Notifications để bắt đầu nhận cảnh báo.

## Evidence
Các minh chứng (evidence) về kết quả triển khai (giao diện cấu hình và email thực tế) được lưu trữ tại file [EVIDENCE.md](EVIDENCE.md) và thư mục `assets/`.
