# Lab: Deploy a Web App on AWS with Terraform

## Mô tả dự án

Dự án này triển khai một hệ thống Web Application hoàn chỉnh trên AWS bằng Terraform, áp dụng kiến trúc **Modular Infrastructure as Code (IaC)** và quản lý state từ xa an toàn.

## Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────┐
│                     VPC (10.0.0.0/16)                       │
│                                                             │
│  ┌─────────────────────┐   ┌──────────────────────────────┐ │
│  │   Public Subnet     │   │     Private Subnets          │ │
│  │   10.0.1.0/24       │   │  10.0.10.0/24 (AZ-a)        │ │
│  │                     │   │  10.0.11.0/24 (AZ-b)        │ │
│  │  ┌───────────────┐  │   │  ┌────────────────────────┐  │ │
│  │  │  EC2 (web-sg) │  │   │  │   RDS MySQL (db-sg)    │  │ │
│  │  │  Web Server   │──│───│──│   Port 3306            │  │ │
│  │  │  Port 80/443  │  │   │  │   publicly_accessible  │  │ │
│  │  └───────────────┘  │   │  │       = false           │  │ │
│  └─────────│───────────┘   │  └────────────────────────┘  │ │
│    ┌───────┴────────┐      └──────────────────────────────┘ │
│    │ Internet GW    │                                       │
│    └───────┬────────┘                                       │
└────────────│────────────────────────────────────────────────┘
             │
         Internet ◄──── S3 Static Assets Bucket
```

## Thành phần chính

| Thành phần | Mô tả |
|------------|-------|
| **VPC** | Mạng riêng ảo với Public và Private Subnets (2 AZ) |
| **EC2** | Web Server chạy trong Public Subnet, tự động cài Apache qua `user_data` |
| **RDS MySQL** | Database chạy trong Private Subnets, chỉ cho phép kết nối từ EC2 |
| **S3** | Bucket lưu trữ static assets (HTML, CSS, JS, Images) với website hosting |
| **Security Groups** | Web SG (port 22/80/443) và DB SG (port 3306 chỉ từ Web SG) |
| **Remote State** | Terraform state lưu trên S3 bucket với DynamoDB locking |

## Cấu trúc thư mục

```
lab/
├── backend-setup/              # Tạo S3 + DynamoDB cho remote state
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── module/                     # Infrastructure chính
│   ├── backend.tf
│   ├── providers.tf
│   ├── main.tf                 # Gọi 5 child modules
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   │
│   ├── vpc/                    # Module: VPC + Subnets + IGW + Route Table
│   ├── sercurity_groups/       # Module: Web SG + DB SG
│   ├── ec2/                    # Module: EC2 Web Server (Dynamic AMI)
│   ├── rds/                    # Module: RDS MySQL
│   └── s3/                     # Module: S3 Static Assets
│
├── evidence-pack.md
└── README.md
```

## Các điểm nổi bật trong thiết kế

- **Dynamic AMI** — Sử dụng `data.aws_ami` để tự động lấy Amazon Linux 2 mới nhất thay vì hardcode AMI ID.
- **Dynamic SSH IP** — Sử dụng `data.http` để tự động lấy IP hiện tại của người dùng gán vào rule SSH, tăng bảo mật.
- **Sensitive Password** — Biến `db_password` được đánh dấu `sensitive = true`, Terraform không hiển thị ra terminal.
- **Modular Architecture** — 5 module độc lập, tái sử dụng được, truyền output giữa các module qua `main.tf` gốc.
- **Security by Design** — RDS hoàn toàn nằm trong Private Subnet, `publicly_accessible = false`, DB SG chỉ nhận traffic từ Web SG.
- **State Backend tách riêng** — Thư mục `backend-setup/` phải được chạy trước để tạo S3 + DynamoDB trước khi chạy project chính.

## Cách sử dụng

```bash
# 1. Tạo backend trước
cd lab/backend-setup
terraform init && terraform apply -auto-approve

# 2. Deploy hạ tầng chính
cd ../module
terraform init && terraform apply -auto-approve

# 3. Dọn dẹp tài nguyên
cd lab/module
terraform destroy -auto-approve

cd ../backend-setup
terraform destroy -auto-approve
```

## Công nghệ sử dụng

- **Terraform** v1.x — Infrastructure as Code
- **AWS Provider** ~> 5.0
- **AWS Services**: VPC, EC2, RDS (MySQL 8.0), S3, DynamoDB, Internet Gateway
