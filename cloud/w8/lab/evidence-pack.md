# Evidence Pack — Week 8 Lab: Deploy a Web App on AWS with Terraform

**Student:** Phan Le Thanh Hoang  
**Date:** 2026-06-06  
**Region:** ap-southeast-1 (Singapore)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                    │
│                     vpc-0d0cc1e13f18bcdc9                    │
│                                                             │
│  ┌─────────────────────┐   ┌──────────────────────────────┐ │
│  │   Public Subnet     │   │     Private Subnets          │ │
│  │   10.0.1.0/24       │   │  10.0.10.0/24 (AZ-a)        │ │
│  │                     │   │  10.0.11.0/24 (AZ-b)        │ │
│  │  ┌───────────────┐  │   │  ┌────────────────────────┐  │ │
│  │  │  EC2 (web-sg) │  │   │  │  RDS MySQL (db-sg)     │  │ │
│  │  │  t3.micro     │──│───│──│  db.t3.micro           │  │ │
│  │  │  54.251.86.41 │  │   │  │  Port 3306             │  │ │
│  │  └───────────────┘  │   │  │  publicly_accessible   │  │ │
│  │         │           │   │  │       = false           │  │ │
│  └─────────│───────────┘   │  └────────────────────────┘  │ │
│            │               └──────────────────────────────┘ │
│    ┌───────┴────────┐                                       │
│    │ Internet GW    │                                       │
│    │ igw-09ee6b...  │                                       │
│    └───────┬────────┘                                       │
└────────────│────────────────────────────────────────────────┘
             │
         Internet ◄──── S3 Static Assets Bucket
                        hoangplt-static-assets-bucket
```

---

## 2. Bước 0 — Backend Setup (S3 + DynamoDB)

### 2.1. `terraform plan` — Backend

```
PS E:\...\lab\backend-setup> terraform plan

Terraform will perform the following actions:

  # aws_dynamodb_table.terraform_lock will be created
  + resource "aws_dynamodb_table" "terraform_lock" {
      + billing_mode = "PAY_PER_REQUEST"
      + hash_key     = "LockID"
      + name         = "hoangplt-terraform-lock-table"
      + attribute {
          + name = "LockID"
          + type = "S"
        }
    }

  # aws_s3_bucket.terraform_state will be created
  + resource "aws_s3_bucket" "terraform_state" {
      + bucket       = "hoangplt-terraform-state-bucket"
      + force_destroy = false
    }

  # aws_s3_bucket_public_access_block.terraform_state will be created
  + resource "aws_s3_bucket_public_access_block" "terraform_state" {
      + block_public_acls       = true
      + block_public_policy     = true
      + ignore_public_acls      = true
      + restrict_public_buckets = true
    }

  # aws_s3_bucket_server_side_encryption_configuration.terraform_state
  + resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
      + rule {
          + apply_server_side_encryption_by_default {
              + sse_algorithm = "AES256"
            }
        }
    }

  # aws_s3_bucket_versioning.terraform_state will be created
  + resource "aws_s3_bucket_versioning" "terraform_state" {
      + versioning_configuration {
          + status = "Enabled"
        }
    }

Plan: 5 to add, 0 to change, 0 to destroy.
```

### 2.2. `terraform apply` — Backend

```
PS E:\...\lab\backend-setup> terraform apply -auto-approve

aws_s3_bucket.terraform_state: Creating...
aws_dynamodb_table.terraform_lock: Creating...
aws_s3_bucket.terraform_state: Creation complete after 4s [id=hoangplt-terraform-state-bucket]
aws_s3_bucket_public_access_block.terraform_state: Creating...
aws_s3_bucket_versioning.terraform_state: Creating...
aws_s3_bucket_server_side_encryption_configuration.terraform_state: Creating...
aws_s3_bucket_public_access_block.terraform_state: Creation complete after 0s
aws_s3_bucket_server_side_encryption_configuration.terraform_state: Creation complete after 1s
aws_s3_bucket_versioning.terraform_state: Creation complete after 2s
aws_dynamodb_table.terraform_lock: Creation complete after 8s

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:
  dynamodb_table_name = "hoangplt-terraform-lock-table"
  s3_bucket_arn       = "arn:aws:s3:::hoangplt-terraform-state-bucket"
  s3_bucket_name      = "hoangplt-terraform-state-bucket"
```

---

## 3. Bước 1–5 — Infrastructure Deployment

### 3.1. `terraform apply` — Main Infrastructure

```
PS E:\...\lab\module> terraform apply -auto-approve

module.security_groups.data.http.myip: Read complete after 0s
module.ec2.data.aws_ami.amazon_linux_2: Read complete after 1s [id=ami-0e8bf7e1d1f339c74]
module.vpc.data.aws_availability_zones.available: Read complete after 1s [id=ap-southeast-1]

module.rds.aws_db_instance.db: Creating...
module.rds.aws_db_instance.db: Still creating... [04m50s elapsed]
module.rds.aws_db_instance.db: Creation complete after 4m55s [id=db-JVI37IYT3NQSKBUPWQTRKMKTNY]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

### 3.2. Terraform Outputs — Final Results

```
Outputs:

db_endpoint         = "terraform-20260606063002939300000001.c3y0wokcajkx.ap-southeast-1.rds.amazonaws.com:3306"
db_sg_id            = "sg-04a3638f66f3489b4"
ec2_instance_id     = "i-057fda409fb876844"
ec2_public_ip       = "54.251.86.41"
public_subnet_id    = "subnet-0bc8732184e6f7a57"
s3_bucket_id        = "hoangplt-static-assets-bucket"
s3_website_endpoint = "hoangplt-static-assets-bucket.s3-website-ap-southeast-1.amazonaws.com"
vpc_id              = "vpc-0d0cc1e13f18bcdc9"
web_sg_id           = "sg-063d1dc751ff87cee"
```

---

## 4. Deployed Resources Summary

| Resource | Type | ID / Value |
|----------|------|------------|
| VPC | `aws_vpc` | `vpc-0d0cc1e13f18bcdc9` |
| Public Subnet | `aws_subnet` | `subnet-0bc8732184e6f7a57` |
| Private Subnet A | `aws_subnet` | `subnet-0e15446e7d4d4b773` |
| Private Subnet B | `aws_subnet` | `subnet-08d74a4a328c5a3c5` |
| Internet Gateway | `aws_internet_gateway` | `igw-09ee6b149464801f3` |
| Route Table | `aws_route_table` | `rtb-0e8464547a96ebbf1` |
| Web Security Group | `aws_security_group` | `sg-063d1dc751ff87cee` |
| DB Security Group | `aws_security_group` | `sg-04a3638f66f3489b4` |
| EC2 Instance | `aws_instance` (t3.micro) | `i-057fda409fb876844` |
| EC2 Public IP | — | `54.251.86.41` |
| RDS MySQL | `aws_db_instance` (db.t3.micro) | `db-JVI37IYT3NQSKBUPWQTRKMKTNY` |
| RDS Endpoint | — | `terraform-2026...ap-southeast-1.rds.amazonaws.com:3306` |
| S3 Bucket | `aws_s3_bucket` | `hoangplt-static-assets-bucket` |
| S3 Website Endpoint | — | `hoangplt-static-assets-bucket.s3-website-ap-southeast-1.amazonaws.com` |
| State Bucket | `aws_s3_bucket` | `hoangplt-terraform-state-bucket` |
| Lock Table | `aws_dynamodb_table` | `hoangplt-terraform-lock-table` |

---

## 5. Security Groups Configuration

### Web Server Security Group (`sg-063d1dc751ff87cee`)

| Direction | Port | Protocol | Source | Purpose |
|-----------|------|----------|--------|---------|
| Ingress | 22 | TCP | My IP (/32) | SSH Access |
| Ingress | 80 | TCP | 0.0.0.0/0 | HTTP |
| Ingress | 443 | TCP | 0.0.0.0/0 | HTTPS |
| Egress | All | All | 0.0.0.0/0 | All outbound |

### Database Security Group (`sg-04a3638f66f3489b4`)

| Direction | Port | Protocol | Source | Purpose |
|-----------|------|----------|--------|---------|
| Ingress | 3306 | TCP | `sg-063d1dc751ff87cee` (web-sg) | MySQL from Web Server only |
| Egress | All | All | 0.0.0.0/0 | All outbound |

---

## 6. Terraform Modular Structure

```
lab/
├── backend-setup/              # Bước 0: Tạo S3 + DynamoDB cho remote state
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
└── module/                     # Bước 1–5: Infrastructure chính
    ├── backend.tf              # Cấu hình S3 backend
    ├── providers.tf            # AWS Provider (ap-southeast-1)
    ├── main.tf                 # Gọi 5 child modules
    ├── variables.tf            # Biến toàn cục (root)
    ├── outputs.tf              # Kết quả sau deploy
    ├── terraform.tfvars        # Giá trị thực tế
    │
    ├── vpc/                    # Module 1: VPC + Subnets + IGW + Route Table
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── sercurity_groups/       # Module 2: Web SG + DB SG
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── ec2/                    # Module 3: EC2 Web Server (Dynamic AMI)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── rds/                    # Module 4: RDS MySQL (Private, not public)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── s3/                     # Module 5: S3 Static Assets Bucket
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 7. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Dynamic AMI (`data.aws_ami`) | Tự động lấy Amazon Linux 2 mới nhất, tránh hardcode AMI ID |
| Dynamic IP cho SSH (`data.http.myip`) | Tự động lấy IP hiện tại của người dùng, tăng bảo mật |
| DB SG chỉ cho phép từ Web SG | Đảm bảo chỉ EC2 mới kết nối được MySQL, không ai khác |
| `publicly_accessible = false` cho RDS | Database không bao giờ được phơi ra Internet |
| `sensitive = true` cho `db_password` | Terraform không in password ra terminal khi plan/apply |
| `skip_final_snapshot = true` | Cho phép `terraform destroy` xóa RDS mà không cần snapshot |
| S3 backend + DynamoDB locking | State được lưu an toàn, mã hóa, có versioning và lock chống xung đột |
| 2 Private Subnets ở 2 AZ | Yêu cầu bắt buộc của AWS RDS Subnet Group |
| `map_public_ip_on_launch = true` | EC2 trong Public Subnet tự động nhận Public IP |
| Tách `backend-setup/` riêng | Backend phải tồn tại trước khi project chính chạy `terraform init` |
