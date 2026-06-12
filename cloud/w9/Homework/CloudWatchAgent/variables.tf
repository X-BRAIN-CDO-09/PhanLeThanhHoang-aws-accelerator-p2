variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair for EC2 access"
  type        = string
  default     = ""
}

variable "dashboard_name" {
  description = "Name of the CloudWatch Dashboard"
  type        = string
  default     = "EC2-Monitoring-Dashboard"
}

variable "cw_agent_namespace" {
  description = "Custom namespace for CloudWatch Agent metrics"
  type        = string
  default     = "CWAgent"
}
