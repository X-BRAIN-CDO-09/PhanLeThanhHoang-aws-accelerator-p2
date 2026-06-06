output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the Public Subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "List of Private Subnet IDs"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}
