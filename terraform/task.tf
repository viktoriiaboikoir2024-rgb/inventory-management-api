resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/inventory-api"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "app" {
  family                   = "inventory-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "inventory-api"
      image     = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "CACHE_ENABLED", value = tostring(var.cache_enabled) },
        { name = "CACHE_TTL",     value = "30" },
        { name = "REDIS_URL",     value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379/0" }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.database_url.arn}:DATABASE_URL::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_iam_role_policy.ecs_secrets_access
  ]
}