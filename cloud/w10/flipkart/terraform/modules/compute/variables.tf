# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
variable "project" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "app_port" {
  type = number
}

variable "irsa_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret the node IAM role is allowed to read"
  type        = string
}
