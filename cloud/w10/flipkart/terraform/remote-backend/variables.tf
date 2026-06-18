# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
variable "aws_region" {
  description = "AWS region where the state bucket + lock table live"
  type        = string
  default     = "ap-southeast-1"
}

variable "project" {
  description = "Resource name prefix"
  type        = string
  default     = "flipkart"
}

variable "state_key" {
  description = "S3 object key for the main stack's terraform.tfstate"
  type        = string
  default     = "w10/flipkart/terraform.tfstate"
}

variable "force_destroy" {
  description = "Allow `terraform destroy` to wipe the bucket even if non-empty. Keep false in shared envs."
  type        = bool
  default     = false
}
