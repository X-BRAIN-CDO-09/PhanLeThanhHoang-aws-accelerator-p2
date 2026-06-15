variable "aws_region" {
  description = "The AWS region to deploy the resources into"
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "The email address to receive root login alerts"
  type        = string
  default     = "hoangk5fc5@gmail.com" # Thay bằng email thật của bạn
}
