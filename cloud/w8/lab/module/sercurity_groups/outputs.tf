output "web_sg_id" {
  description = "The ID of the Web Server Security Group"
  value       = aws_security_group.web-sg.id
}

output "db_sg_id" {
  description = "The ID of the Database Security Group"
  value       = aws_security_group.db-sg.id
}
