variable "private_subnet_ids" {
  description = "List of Private Subnet IDs for RDS Subnet Group (requires at least 2 AZs)"
  type        = list(string)
}

variable "instance_class" {
  description = "The RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "The allocated storage size in GB for the RDS instance"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
}

variable "db_username" {
  description = "The master username for the database"
  type        = string
}

variable "db_password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
}

variable "db_sg_id" {
  description = "The Security Group ID for the RDS instance"
  type        = string
}
