resource "aws_db_subnet_group" "main" {
  name       = "inventory-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "inventory-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "inventory-database"

  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "inventory"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  auto_minor_version_upgrade = true

  tags = {
    Name = "inventory-database"
  }
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.main.address
}