resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_db_instance" "db" {
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "web-app-db"
  }
}
