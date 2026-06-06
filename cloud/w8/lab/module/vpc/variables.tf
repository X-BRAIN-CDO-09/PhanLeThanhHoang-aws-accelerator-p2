variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the Public Subnet"
  type        = string
}

variable "private_subnet_cidr_a" {
  description = "CIDR block for the first Private Subnet (AZ-a)"
  type        = string
}

variable "private_subnet_cidr_b" {
  description = "CIDR block for the second Private Subnet (AZ-b)"
  type        = string
}

variable "public_route_cidr" {
  description = "CIDR block for the public route (Internet access)"
  type        = string
  default     = "0.0.0.0/0"
}
