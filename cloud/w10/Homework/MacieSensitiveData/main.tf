provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# 1. S3 Bucket
resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "data_bucket" {
  bucket        = "macie-sensitive-data-${random_id.bucket_id.hex}"
  force_destroy = true
}

# Upload sample file
resource "aws_s3_object" "sample_file" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "sample_data.txt"
  source = "${path.module}/sample_data.txt"
  etag   = filemd5("${path.module}/sample_data.txt")
}

# Upload internal-note.txt
resource "aws_s3_object" "internal_note" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "internal-note.txt"
  source = "${path.module}/internal-note.txt"
  etag   = filemd5("${path.module}/internal-note.txt")
}

# 2. Enable Macie
resource "aws_macie2_account" "macie_account" {
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                       = "ENABLED"
}

# Wait for Macie service-linked role propagation
resource "time_sleep" "wait_for_macie" {
  depends_on      = [aws_macie2_account.macie_account]
  create_duration = "90s"
}

# 2.5 Custom Data Identifier to detect our secret pattern
resource "aws_macie2_custom_data_identifier" "confidential_secret" {
  name        = "ConfidentialCustomerSecret"
  description = "Detects CONFIDENTIAL_CUSTOMER_SECRET patterns"
  regex       = "CONFIDENTIAL_CUSTOMER_SECRET_[A-Z0-9]{24}"

  depends_on = [aws_macie2_account.macie_account]
}

# 3. Create Macie Classification Job with Custom Data Identifier
resource "aws_macie2_classification_job" "sensitive_data_job" {
  job_type                   = "ONE_TIME"
  name                       = "Scan-Sensitive-Data-Job-V6"
  custom_data_identifier_ids = [aws_macie2_custom_data_identifier.confidential_secret.id]

  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = [aws_s3_bucket.data_bucket.id]
    }
  }

  depends_on = [
    time_sleep.wait_for_macie,
    aws_s3_object.sample_file,
    aws_s3_object.internal_note
  ]
}

# 4. SNS Topic for Alerts
resource "aws_sns_topic" "macie_alerts" {
  name = "macie-alerts-topic"
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.macie_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.macie_alerts.arn]
  }
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.macie_alerts.arn
  protocol  = "email"
  endpoint  = var.email_address
}

# 5. EventBridge Rule to capture Macie Findings
resource "aws_cloudwatch_event_rule" "macie_findings_rule" {
  name        = "macie-findings-rule"
  description = "Capture Amazon Macie Findings"

  event_pattern = jsonencode({
    source        = ["aws.macie"]
    "detail-type" = ["Macie Finding"]
  })
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.macie_findings_rule.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.macie_alerts.arn
}
