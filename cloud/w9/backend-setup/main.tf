terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# 1. Tạo S3 Bucket để chứa state file
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "hoangplt-w9-terraform-state-bucket"
  force_destroy = true # Cho phép tự xóa các object bên trong khi destroy
}

# 2. Bật versioning (Để lỡ tay xóa state vẫn có thể khôi phục bản cũ)
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Mã hóa file trên S3
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Tạo DynamoDB Table dùng để khóa state (State Locking)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "hoangplt-w9-terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table"
}
