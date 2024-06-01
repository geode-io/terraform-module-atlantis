resource "aws_efs_file_system" "this" {
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
  encrypted        = true
  kms_key_id       = var.efs_kms_key_id

  tags = {
    Name = var.name
  }
}

resource "aws_efs_mount_target" "this" {
  for_each = toset(var.task_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id
  root_directory {
    path = "/atlantis"
    creation_info {
      owner_uid   = 100
      owner_gid   = 1000
      permissions = "755"
    }
  }
  posix_user {
    uid = 100
    gid = 1000
  }

  tags = {
    Name = "${var.name}-ecs"
  }
}

resource "aws_efs_file_system_policy" "this" {
  file_system_id = aws_efs_file_system.this.id
  policy         = data.aws_iam_policy_document.efs_file_system.json
}

data "aws_iam_policy_document" "efs_file_system" {

  statement {
    sid    = "EnforceInTransitEncryption"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["*"]
    resources = [aws_efs_file_system.this.arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowECSTaskMount"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.task.arn]
    }
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]
    resources = [aws_efs_file_system.this.arn]
    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }
}

resource "aws_security_group" "efs" {
  name   = "${var.name}-efs"
  vpc_id = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    security_groups = [aws_security_group.ecs.id]
  }
}
