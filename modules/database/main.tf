resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-${var.environment}-db-subnet"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.app_name}-${var.environment}-db-subnet"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_instance" "app_db" {
  identifier        = "${var.app_name}-${var.environment}-db"
  engine            = "sqlserver-ex"
  engine_version    = "15.00"
  instance_class    = "db.t3.small"
  allocated_storage = 20
  username          = "admin"
  password          = "ChangeMe123!"
  license_model     = "license-included"

  multi_az                = var.multi_az
  skip_final_snapshot     = true
  backup_retention_period = var.backup_retention_days

  vpc_security_group_ids = [var.db_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  tags = {
    Name        = "${var.app_name}-${var.environment}-db"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}