output "db_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.db.endpoint
}

output "db_name" {
  description = "The name of the database"
  value       = aws_db_instance.db.db_name
}
