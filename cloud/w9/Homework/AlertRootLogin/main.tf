provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# =======================================================
# 1. S3 Bucket cho CloudTrail
# =======================================================
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "cloudtrail-root-alert-bucket-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# =======================================================
# 2. CloudWatch Log Group & IAM Role cho CloudTrail
# =======================================================
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "/aws/cloudtrail/root-login-alert-logs"
  retention_in_days = 7
}

resource "aws_iam_role" "cloudtrail_cw_role" {
  name = "CloudTrailCWLogsRoleForRootAlert"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cw_policy" {
  name = "CloudTrailCWLogsPolicyForRootAlert"
  role = aws_iam_role.cloudtrail_cw_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailCreateLogStream"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
      }
    ]
  })
}

# =======================================================
# 3. Kích hoạt CloudTrail
# =======================================================
resource "aws_cloudtrail" "main_trail" {
  name                          = "root-login-alert-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cw_role.arn

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_bucket_policy
  ]
}

# =======================================================
# 4. CloudWatch Metric Filter cho Root Login
# =======================================================
resource "aws_cloudwatch_log_metric_filter" "root_login_filter" {
  name           = "RootAccountLoginFilter"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "RootAccountLoginEvent"
    namespace = "Security"
    value     = "1"
  }
}

# =======================================================
# 5. SNS Topic & Subscription (Email Alert)
# =======================================================
resource "aws_sns_topic" "root_login_alerts" {
  name = "root-login-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.root_login_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# =======================================================
# 6. CloudWatch Metric Alarm
# =======================================================
resource "aws_cloudwatch_metric_alarm" "root_login_alarm" {
  alarm_name          = "Alert-Root-Login"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.root_login_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.root_login_filter.metric_transformation[0].namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Triggers when a root account login is detected via CloudTrail logs."
  alarm_actions       = [aws_sns_topic.root_login_alerts.arn]
  treat_missing_data  = "notBreaching"
}
