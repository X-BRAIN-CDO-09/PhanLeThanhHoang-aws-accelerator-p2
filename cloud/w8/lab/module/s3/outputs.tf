output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.static_assets.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.static_assets.arn
}

output "website_endpoint" {
  description = "The website endpoint of the S3 bucket"
  value       = aws_s3_bucket_website_configuration.static_assets.website_endpoint
}
