resource "aws_s3_bucket" "static_assets" {
  bucket = var.bucket_name

  tags = {
    Name = "Static Assets Bucket"
  }
}

# Cấu hình website hosting (tách riêng theo AWS Provider v4+)
resource "aws_s3_bucket_website_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  index_document {
    suffix = "index.html"
  }
}

# Bật versioning để bảo vệ dữ liệu
resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cho phép public access (cần thiết để dùng ACL public-read)
resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  depends_on = [aws_s3_bucket_public_access_block.static_assets]
}

resource "aws_s3_bucket_acl" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  acl    = "public-read"

  depends_on = [aws_s3_bucket_ownership_controls.static_assets]
}
