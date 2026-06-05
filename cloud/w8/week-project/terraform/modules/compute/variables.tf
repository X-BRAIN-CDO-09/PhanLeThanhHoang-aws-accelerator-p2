variable "instance_type" {
  type = string
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "app_port" {
  type = number
}
