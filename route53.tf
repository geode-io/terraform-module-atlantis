locals {
  dns_name = var.dns_name != null ? var.dns_name : var.name
  fqdn     = "${local.dns_name}.${var.route53_zone_name}"
}

data "aws_route53_zone" "target" {
  name = var.route53_zone_name
}

resource "aws_route53_record" "this_a" {
  name    = local.dns_name
  type    = "A"
  zone_id = data.aws_route53_zone.target.zone_id

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "this_aaaa" {
  name    = local.dns_name
  type    = "AAAA"
  zone_id = data.aws_route53_zone.target.zone_id

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = false
  }
}
