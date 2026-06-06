variable "vpc_id" {
  description = "The ID of the VPC where security groups will be created"
  type        = string
}

variable "web_ingress_cidr_blocks" {
  description = "CIDR blocks for web ingress traffic (HTTP/HTTPS)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "egress_cidr_blocks" {
  description = "CIDR blocks for egress traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
