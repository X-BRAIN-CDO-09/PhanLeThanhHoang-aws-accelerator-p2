# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
variable "aws_region" {
  description = "AWS region for the flipkart foundation"
  type        = string
  default     = "ap-southeast-1"
}

variable "project" {
  description = "Resource name prefix"
  type        = string
  default     = "flipkart"
}

variable "instance_type" {
  description = "EC2 type for full W9 stack: MERN + MongoDB + kube-prometheus-stack + Argo Rollouts + ESO + Sigstore (needs >= 12GB RAM)"
  type        = string
  default     = "t3.xlarge"
}

variable "app_port" {
  description = "NodePort exposed by the Flipkart frontend Service / ALB target port"
  type        = number
  default     = 30000
}

variable "db_secret_name" {
  description = "Name of the AWS Secrets Manager secret consumed by ESO (Lab 2.1)"
  type        = string
  default     = "prod/db/password"
}

variable "db_initial_password" {
  description = "Initial value of the DB password stored in Secrets Manager. Override with TF_VAR_db_initial_password."
  type        = string
  default     = "ChangeMe-Initial-Password-1"
  sensitive   = true
}
