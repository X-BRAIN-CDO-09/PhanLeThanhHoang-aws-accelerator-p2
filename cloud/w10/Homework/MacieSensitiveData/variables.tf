variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-southeast-1"
}

variable "email_address" {
  description = "The email address to receive SNS alerts for Amazon Macie findings"
  type        = string
  default     = "ringhost42@gmail.com"
}
