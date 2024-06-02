locals {
  ecs_cluster_name = var.ecs_cluster_name != null ? var.ecs_cluster_name : var.name
  ecs_cluster_id   = var.create_ecs_cluster ? aws_ecs_cluster.this[0].id : data.aws_ecs_cluster.target[0].id

  atlantis_container_name = "atlantis"
  atlantis_container_port = 4141
  atlantis_data_dir       = "/atlantis/data"
}

data "aws_ecs_cluster" "target" {
  count        = var.create_ecs_cluster ? 0 : 1
  cluster_name = local.ecs_cluster_name
}

resource "aws_ecs_cluster" "this" {
  count = var.create_ecs_cluster ? 1 : 0
  name  = local.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_security_group" "ecs" {
  name   = "${var.name}-ecs"
  vpc_id = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = local.atlantis_container_port
    to_port         = local.atlantis_container_port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ecs_service" "this" {
  name                              = var.name
  cluster                           = local.ecs_cluster_id
  task_definition                   = aws_ecs_task_definition.this.arn
  launch_type                       = "FARGATE"
  desired_count                     = var.high_availability ? var.task_desired_count : 1
  health_check_grace_period_seconds = 10
  enable_execute_command            = true

  network_configuration {
    security_groups = [aws_security_group.ecs.id]
    subnets         = var.task_subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.atlantis_container_name
    container_port   = local.atlantis_container_port
  }

  depends_on = [
    aws_efs_mount_target.this,
    aws_efs_access_point.this
  ]
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  container_definitions = jsonencode([
    {
      name      = local.atlantis_container_name
      image     = "${var.image_name}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = local.atlantis_container_port
          hostPort      = local.atlantis_container_port
          protocol      = "tcp"
        }
      ]

      linuxParameters = {
        initProcessEnabled = true
      }

      environment = concat(
        [
          {
            name  = "ATLANTIS_ATLANTIS_URL",
            value = "https://${aws_route53_record.this_a.fqdn}",
          },
          {
            name  = "ATLANTIS_DATA_DIR",
            value = local.atlantis_data_dir,
          },
          {
            name  = "ATLANTIS_LOCKING_DB_TYPE",
            value = var.high_availability ? "redis" : "boltdb",
          },
          {
            name  = "ATLANTIS_REPO_ALLOWLIST",
            value = join(",", var.repo_allowlist),
          },
          {
            name  = "ATLANTIS_GH_APP_SLUG",
            value = var.github_app_slug,
          },
          {
            name  = "ATLANTIS_GH_APP_ID",
            value = tostring(var.github_app_id),
          },
        ],
        var.high_availability ? [
          {
            name  = "ATLANTIS_REDIS_HOST",
            value = aws_elasticache_serverless_cache.this[0].endpoint[0].address,
          },
          {
            name  = "ATLANTIS_REDIS_TLS_ENABLED",
            value = "true",
          },
        ] : [],
        [
          {
            name  = "ATLANTIS_WRITE_GIT_CREDS",
            value = tostring(var.atlantis_write_git_creds),
          },
          {
            name  = "ATLANTIS_AUTOMERGE",
            value = tostring(var.atlantis_automerge),
          },
          {
            name  = "ATLANTIS_AUTOPLAN_MODULES",
            value = tostring(var.atlantis_autoplan_modules),
          },
          {
            name  = "ATLANTIS_HIDE_PREV_PLAN_COMMENTS",
            value = tostring(var.atlantis_hide_prev_plan_comments),
          },
          {
            name  = "ATLANTIS_ENABLE_DIFF_MARKDOWN_FORMAT",
            value = tostring(var.atlantis_enable_diff_markdown_format),
          },
          {
            name  = "ATLANTIS_HIDE_UNCHANGED_PLAN_COMMENTS",
            value = tostring(var.atlantis_hide_unchanged_plan_comments),
          },
        ],
        [for key, value in var.extra_env_vars : {
          name  = key
          value = value
        }],
      )

      secrets = [
        {
          name      = "ATLANTIS_GH_APP_KEY",
          valueFrom = "${aws_secretsmanager_secret.atlantis.arn}:github_app_private_key::"
        },
        {
          name      = "ATLANTIS_GH_WEBHOOK_SECRET",
          valueFrom = "${aws_secretsmanager_secret.atlantis.arn}:github_webhook_secret::"
        },
      ]

      mountPoints = [
        {
          sourceVolume  = "atlantis-data"
          containerPath = local.atlantis_data_dir
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = "us-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  volume {
    name = "atlantis-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.this.id
      transit_encryption = "ENABLED"
      authorization_config {
        iam             = "ENABLED"
        access_point_id = aws_efs_access_point.this.id
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = 90
}
