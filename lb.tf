resource "aws_lb" "this" {
  name               = var.name
  load_balancer_type = "application"
  subnets            = var.lb_subnet_ids
  security_groups    = [aws_security_group.lb.id]
  ip_address_type    = var.lb_ip_address_type
}

# allow webhook events without load balancer auth
resource "aws_lb_listener_rule" "events" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/events"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# allow webhook events without load balancer auth
resource "aws_lb_listener_rule" "ui" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  action {
    type = "authenticate-oidc"
    authenticate_oidc {
      authorization_endpoint = var.oidc_authorization_endpoint
      client_id              = var.oidc_client_id
      client_secret          = var.oidc_client_secret
      issuer                 = var.oidc_issuer
      token_endpoint         = var.oidc_token_endpoint
      user_info_endpoint     = var.oidc_user_info_endpoint
      session_timeout        = var.oidc_session_timeout_seconds
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_target_group" "this" {
  name                 = var.name
  vpc_id               = var.vpc_id
  port                 = local.atlantis_container_port
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 10

  health_check {
    path     = "/healthz"
    interval = 10
  }
}

resource "aws_lb_listener" "https" {
  port              = 443
  protocol          = "HTTPS"
  load_balancer_arn = aws_lb.this.arn
  certificate_arn   = aws_acm_certificate.this.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = "401"
      content_type = "application/json"
      message_body = "{\"message\": \"Unauthorized\"}"
    }
  }

  depends_on = [aws_acm_certificate_validation.this]
}

resource "aws_lb_listener" "http" {
  port              = 80
  protocol          = "HTTP"
  load_balancer_arn = aws_lb.this.arn

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_security_group" "lb" {
  name   = var.name
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
