variable "aws_region" {
  description = "AWS Region để triển khai hạ tầng"
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "Loại máy EC2 dùng cho Minikube (Cần ít nhất 2 CPU, 2GB RAM)"
  type        = string
  default     = "t3.small"
}

variable "app_port" {
  description = "Port dùng cho NodePort và ALB Target Group"
  type        = number
  default     = 30000
}
