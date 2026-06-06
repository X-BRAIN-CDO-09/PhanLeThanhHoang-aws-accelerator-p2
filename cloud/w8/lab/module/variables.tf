# ===========================
# General
# ===========================
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

# ===========================
# VPC Module
# ===========================
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the Public Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr_a" {
  description = "CIDR block for the first Private Subnet (AZ-a)"
  type        = string
  default     = "10.0.10.0/24"
}

variable "private_subnet_cidr_b" {
  description = "CIDR block for the second Private Subnet (AZ-b)"
  type        = string
  default     = "10.0.11.0/24"
}

# ===========================
# EC2 Module
# ===========================
variable "instance_type" {
  description = "EC2 instance type for the Web Server"
  type        = string
  default     = "t3.micro"
}

# ===========================
# RDS Module
# ===========================
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "webappdb"
}

variable "db_username" {
  description = "The master username for the database"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
}

# ===========================
# S3 Module
# ===========================
variable "bucket_name" {
  description = "The name of the S3 bucket for static assets"
  type        = string
}
