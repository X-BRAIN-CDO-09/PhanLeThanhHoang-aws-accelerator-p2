variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the Public Subnet where the EC2 will be deployed"
  type        = string
}

variable "security_group_id" {
  description = "The ID of the Security Group for the Web Server"
  type        = string
}

variable "user_data" {
  description = "User data script to run on instance start (Optional)"
  type        = string
  default     = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Welcome to AWS Web Server deployed via Terraform!</h1>" | sudo tee /var/www/html/index.html
              EOF
}
