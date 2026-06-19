output "s3_bucket_name" {
  description = "Name of the S3 bucket created for Macie to scan"
  value       = aws_s3_bucket.data_bucket.bucket
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.macie_alerts.arn
}

output "macie_job_id" {
  description = "The ID of the Amazon Macie classification job"
  value       = aws_macie2_classification_job.sensitive_data_job.id
}
