########################
# Secrets Manager
########################

# Define Secrets Manager secret
resource "aws_secretsmanager_secret" "main" {
  name                    = "${var.common.env}/mysql"
  description             = "Secret for ${var.common.env}-db-mysql"
  recovery_window_in_days = 0
}

# Define secret values
resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_string = jsonencode(local.db_parameters)
}

locals {
  db_parameters = {
    host     = var.rds.db_instance_address
    dbname   = var.db_info.name
    username = var.db_info.db_user_name
    password = var.db_info.db_user_password
  }
}
