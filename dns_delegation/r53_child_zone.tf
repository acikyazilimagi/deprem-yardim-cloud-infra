locals {
  delegated_zone_name = "${var.child}.${var.parent}"
}

resource "aws_route53_zone" "child" {
  name     = local.delegated_zone_name
  provider = aws.target
}

resource "aws_route53_record" "domain_delegation_record" {
  zone_id  = var.parent_zone_id
  name     = local.delegated_zone_name
  type     = "NS"
  ttl      = 3600
  records  = aws_route53_zone.child.name_servers
  provider = aws.target
}
