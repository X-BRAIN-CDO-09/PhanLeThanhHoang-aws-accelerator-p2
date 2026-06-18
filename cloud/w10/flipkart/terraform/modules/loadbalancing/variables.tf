# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "app_port" {
  type = number
}
