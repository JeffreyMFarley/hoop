output "user" {
  value = var.db_username
}

output "password_arn" {
  value = aws_secretsmanager_secret_version.db_password.arn
}

output "db_name" {
  value = var.db_name
}

output "host" {
  value = aws_db_instance.main.address
}

output "password" {
  value = random_string.db_password.result
}
