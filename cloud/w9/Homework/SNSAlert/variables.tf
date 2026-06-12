variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-southeast-1"
}

variable "alert_email" {
  description = "The email address to send CPU alerts to"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "alarm_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "alarm_period" {
  description = "The period in seconds over which the specified statistic is applied."
  type        = number
  default     = 300
}

variable "alarm_threshold" {
  description = "The value against which the specified statistic is compared."
  type        = number
  default     = 80
}
