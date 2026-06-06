variable "aws_region" {
  description = "AWS region to deploy backend resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "hoangplt-terraform-state-bucket"
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "hoangplt-terraform-lock-table"
}
