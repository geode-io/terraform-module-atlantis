resource "aws_elasticache_serverless_cache" "this" {
  name                 = var.name
  description          = "Lock database for the ${var.name} Atlantis deployment"
  engine               = "redis"
  major_engine_version = "7"
  subnet_ids           = var.task_subnet_ids
  security_group_ids   = [aws_security_group.elasticache.id]

  cache_usage_limits {
    data_storage {
      maximum = 25
      unit    = "GB"
    }
  }
}

resource "aws_security_group" "elasticache" {
  name_prefix = "${var.name}-elasticache"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6380
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
