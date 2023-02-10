locals {
  root_domain = "afet.org"
  sub_domains = {
    beniyiyim   = "beniyiyim"
    depremio    = "deprem"
    eczane      = "eczane"
    discordbot  = "discord.bot"
    telegrambot = "telegram.bot"
    api         = "api"
    apigo       = "apigo"
    goconsumer  = "consumer"
    worker      = "worker"
  }
}

resource "aws_route53_zone" "root_domain" {
  name = local.root_domain
}

module "dns" {
  for_each = locals.sub_domains
  source   = "./dns_delegation"

  parent_zone_id = aws_route53_zone.root_domain.zone_id
  parent         = local.root_domain
  child          = each.value

  providers = {
    aws.source = aws
    aws.target = aws
  }
}