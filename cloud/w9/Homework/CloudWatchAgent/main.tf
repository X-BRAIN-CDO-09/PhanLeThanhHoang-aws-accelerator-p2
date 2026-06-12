provider "aws" {
  region = var.aws_region
}

# ============================================================
# 0. Data Sources
# ============================================================
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ============================================================
# Prerequisite: IAM Role with CloudWatchAgentServerPolicy
# ============================================================
resource "aws_iam_role" "cloudwatch_agent_role" {
  name = "EC2-CloudWatchAgent-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "EC2-CloudWatchAgent-Role"
  }
}

# Attach the CloudWatchAgentServerPolicy (AWS managed policy)
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.cloudwatch_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach AmazonSSMManagedInstanceCore for SSM Session Manager access
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.cloudwatch_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create Instance Profile to attach role to EC2
resource "aws_iam_instance_profile" "cloudwatch_agent_profile" {
  name = "EC2-CloudWatchAgent-Profile"
  role = aws_iam_role.cloudwatch_agent_role.name
}

# Security Group for SSH access (fallback)
resource "aws_security_group" "allow_ssh" {
  name        = "cloudwatch-agent-ssh"
  description = "Allow SSH inbound traffic for CloudWatch Agent EC2"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CloudWatchAgent-SSH"
  }
}

# ============================================================
# 1. EC2 Instance with CloudWatch Agent Installation
# ============================================================
# Steps from the training material:
#   Step 1: Install the Agent Package
#   Step 2: Run Configuration Wizard (automated via config JSON)
#   Step 3: Start the Agent
#   Step 4: Verify & Check Status

resource "aws_instance" "monitored_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.cloudwatch_agent_profile.name
  key_name               = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # -----------------------------------------------
              # Step 1: Install the Agent Package
              # -----------------------------------------------
              # sudo yum install amazon-cloudwatch-agent -y
              dnf install -y amazon-cloudwatch-agent

              # -----------------------------------------------
              # Step 2: Configure the Agent (automated JSON config)
              # Instead of running the interactive wizard:
              #   sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
              # We provide a pre-built configuration file.
              # -----------------------------------------------
              cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CONFIG'
              {
                "agent": {
                  "metrics_collection_interval": 60,
                  "run_as_user": "root"
                },
                "metrics": {
                  "namespace": "${var.cw_agent_namespace}",
                  "append_dimensions": {
                    "InstanceId": "$${aws:InstanceId}",
                    "AutoScalingGroupName": "$${aws:AutoScalingGroupName}"
                  },
                  "aggregation_dimensions": [["InstanceId"]],
                  "metrics_collected": {
                    "cpu": {
                      "measurement": [
                        "cpu_usage_idle",
                        "cpu_usage_iowait",
                        "cpu_usage_user",
                        "cpu_usage_system"
                      ],
                      "metrics_collection_interval": 60,
                      "totalcpu": true,
                      "resources": ["*"]
                    },
                    "disk": {
                      "measurement": [
                        "used_percent",
                        "inodes_free"
                      ],
                      "metrics_collection_interval": 60,
                      "resources": ["*"]
                    },
                    "diskio": {
                      "measurement": [
                        "io_time"
                      ],
                      "metrics_collection_interval": 60,
                      "resources": ["*"]
                    },
                    "mem": {
                      "measurement": [
                        "mem_used_percent",
                        "mem_available_percent"
                      ],
                      "metrics_collection_interval": 60
                    },
                    "swap": {
                      "measurement": [
                        "swap_used_percent"
                      ],
                      "metrics_collection_interval": 60
                    },
                    "net": {
                      "measurement": [
                        "bytes_sent",
                        "bytes_recv",
                        "packets_sent",
                        "packets_recv"
                      ],
                      "metrics_collection_interval": 60,
                      "resources": ["*"]
                    }
                  }
                }
              }
              CONFIG

              # -----------------------------------------------
              # Step 3: Start the Agent
              # -----------------------------------------------
              # sudo systemctl enable amazon-cloudwatch-agent
              # sudo systemctl start amazon-cloudwatch-agent
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config \
                -m ec2 \
                -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
                -s

              systemctl enable amazon-cloudwatch-agent

              # -----------------------------------------------
              # Step 4: Verify & Check Status
              # -----------------------------------------------
              # sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -m ec2 \
                -a status
              EOF

  tags = {
    Name = "CloudWatchAgent-MonitoredServer"
  }
}

# ============================================================
# 2. CloudWatch Dashboard — EC2 Monitoring
# ============================================================
resource "aws_cloudwatch_dashboard" "ec2_monitoring" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      # Row 1: CPU Metrics
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "CPU Utilization (Built-in)"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.monitored_server.id]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "CPU Usage (CW Agent - User/System/IOWait)"
          metrics = [
            [var.cw_agent_namespace, "cpu_usage_user",   "InstanceId", aws_instance.monitored_server.id],
            [var.cw_agent_namespace, "cpu_usage_system", "InstanceId", aws_instance.monitored_server.id],
            [var.cw_agent_namespace, "cpu_usage_iowait", "InstanceId", aws_instance.monitored_server.id]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
        }
      },

      # Row 2: Memory & Swap
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Memory Used %"
          metrics = [
            [var.cw_agent_namespace, "mem_used_percent", "InstanceId", aws_instance.monitored_server.id]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
          yAxis  = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Swap Used %"
          metrics = [
            [var.cw_agent_namespace, "swap_used_percent", "InstanceId", aws_instance.monitored_server.id]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
          yAxis  = { left = { min = 0, max = 100 } }
        }
      },

      # Row 3: Disk & Network
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title   = "Disk Used %"
          metrics = [
            [var.cw_agent_namespace, "disk_used_percent", "InstanceId", aws_instance.monitored_server.id]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
          yAxis  = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title   = "Network I/O (Bytes Sent/Recv)"
          metrics = [
            [var.cw_agent_namespace, "net_bytes_sent", "InstanceId", aws_instance.monitored_server.id],
            [var.cw_agent_namespace, "net_bytes_recv", "InstanceId", aws_instance.monitored_server.id]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
        }
      },

      # Row 4: Instance Status
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          title   = "EC2 Status Check Failed"
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.monitored_server.id],
            ["AWS/EC2", "StatusCheckFailed_Instance", "InstanceId", aws_instance.monitored_server.id],
            ["AWS/EC2", "StatusCheckFailed_System", "InstanceId", aws_instance.monitored_server.id]
          ]
          period = 300
          stat   = "Maximum"
          region = var.aws_region
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          title   = "EC2 Network (Built-in)"
          metrics = [
            ["AWS/EC2", "NetworkIn",  "InstanceId", aws_instance.monitored_server.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.monitored_server.id]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
        }
      }
    ]
  })
}

# ============================================================
# Outputs
# ============================================================
output "instance_id" {
  description = "ID of the EC2 instance with CloudWatch Agent"
  value       = aws_instance.monitored_server.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.monitored_server.public_ip
}

output "iam_role_arn" {
  description = "ARN of the IAM Role with CloudWatchAgentServerPolicy"
  value       = aws_iam_role.cloudwatch_agent_role.arn
}

output "dashboard_url" {
  description = "URL of the CloudWatch Dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.dashboard_name}"
}
