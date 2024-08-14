locals {
  datadog_container_definition = var.datadog_enabled ? {
    name      = "datadog-agent"
    image     = "public.ecr.aws/datadog/agent:7"
    essential = true

    environment = [
      {
        name  = "ECS_FARGATE"
        value = "true"
      }
    ]

    secrets = [
      {
        name      = "DD_API_KEY"
        valueFrom = data.aws_secretsmanager_secret.datadog_api_key[0].arn
      },
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "agent health"]
      startPeriod = 15
      interval    = 30
      timeout     = 5
      retries     = 3
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  } : null
}

data "aws_secretsmanager_secret" "datadog_api_key" {
  count = var.datadog_enabled ? 1 : 0
  name  = var.datadog_api_key_secretsmanager_secret_name
}
