# Templates to be used for DNS record management (Route53 and/or Cloudflare)

############################## Route53 (optional) ##############################

resource "aws_route53_record" "route53_standard" {
  count = var.enable_route53 && var.route53_alias == null ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = var.route53_record_type
  ttl     = var.route53_record_ttl
  records = var.route53_record_values
}

resource "aws_route53_record" "route53_alias" {
  count = var.enable_route53 && var.route53_alias != null ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = var.route53_record_type

  alias {
    name                   = var.route53_alias.name
    zone_id                = var.route53_alias.zone_id
    evaluate_target_health = try(var.route53_alias.evaluate_target_health, true)
  }
}

############################## Cloudflare (optional) ##############################

resource "cloudflare_dns_record" "cloudflare_record" {
  for_each = var.enable_cloudflare ? { for idx, v in var.cloudflare_record_values : tostring(idx) => v } : {}

  zone_id = var.cloudflare_zone_id
  name    = var.cloudflare_record_name
  type    = var.cloudflare_record_type
  content = each.value
  ttl     = var.cloudflare_record_ttl
  proxied = var.cloudflare_record_proxied
  comment = var.cloudflare_record_comment
}
