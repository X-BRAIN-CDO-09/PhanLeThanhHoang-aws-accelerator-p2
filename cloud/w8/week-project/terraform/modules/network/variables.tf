variable "vpc_id" {
  description = "VPC ID để tạo Security Group"
  type        = string
}

variable "app_port" {
  description = "Port của ứng dụng"
  type        = number
}
