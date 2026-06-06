# ===========================
# VPC Outputs
# ===========================
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "The ID of the Public Subnet"
  value       = module.vpc.public_subnet_id
}

# ===========================
# Security Groups Outputs
# ===========================
output "web_sg_id" {
  description = "The ID of the Web Server Security Group"
  value       = module.security_groups.web_sg_id
}

output "db_sg_id" {
  description = "The ID of the Database Security Group"
  value       = module.security_groups.db_sg_id
}

# ===========================
# EC2 Outputs
# ===========================
output "ec2_instance_id" {
  description = "The ID of the EC2 Web Server instance"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "The Public IP of the EC2 Web Server"
  value       = module.ec2.public_ip
}

# ===========================
# RDS Outputs
# ===========================
output "db_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = module.rds.db_endpoint
}

# ===========================
# S3 Outputs
# ===========================
output "s3_bucket_id" {
  description = "The ID of the S3 bucket"
  value       = module.s3.bucket_id
}

output "s3_website_endpoint" {
  description = "The website endpoint of the S3 bucket"
  value       = module.s3.website_endpoint
}
