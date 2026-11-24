resource "aws_secretsmanager_secret" "database_url" {
  name        = "inventory/database-url"
  description = "Database connection string for Inventory API"

  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id = aws_secretsmanager_secret.database_url.id

  secret_string = jsonencode({
    DATABASE_URL = "postgresql+psycopg://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:5432/inventory"
  })
}

resource "aws_iam_role_policy" "ecs_secrets_access" {
  name = "inventory-ecs-secrets-access"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.database_url.arn
      }
    ]
  })
}
