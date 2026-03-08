output "db_endpoint" {
  value = aws_db_instance.app_db.endpoint
}

output "db_name" {
  value = aws_db_instance.app_db.db_name
}