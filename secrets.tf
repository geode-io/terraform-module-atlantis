resource "aws_secretsmanager_secret" "atlantis" {
  name = var.name
}

resource "aws_secretsmanager_secret_version" "atlantis" {
  secret_id     = aws_secretsmanager_secret.atlantis.id
  secret_string = jsonencode({
    github_app_private_key     = var.github_app_private_key
    github_webhook_secret      = var.github_webhook_secret
  })
}