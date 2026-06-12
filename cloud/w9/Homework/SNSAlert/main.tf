provider "aws" {
  region = var.aws_region
}

# 0. Create an EC2 Instance
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # Cài đặt và tự động chạy quá tải CPU trong 10 phút (600s) ngay khi khởi động để test Alarm
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y stress
              stress --cpu 4 --timeout 600s
              EOF

  tags = {
    Name = "AppServer"
  }
}

# 1. Create SNS Topic
resource "aws_sns_topic" "cpu_alerts" {
  name = "ec2-cpu-alerts"
}

# 2. Add Email Subscription
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 3 & 4. Create CloudWatch Alarm and Set SNS Notification Action
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "ec2-cpu-high-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.alarm_threshold

  dimensions = {
    InstanceId = aws_instance.app_server.id
  }

  alarm_description = "Send an email alert when EC2 CPU > 80% for 5 consecutive minutes"
  
  # Action when entering ALARM state
  alarm_actions = [aws_sns_topic.cpu_alerts.arn]
  
  # Optional: Action when returning to OK state (recovery alert)
  ok_actions = [aws_sns_topic.cpu_alerts.arn]
}
