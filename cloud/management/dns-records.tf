############################## DNS (Cloudflare + Route53) ##############################
# AWS is authoritative for the management subdomain hosted zone.
# Cloudflare remains authoritative for the parent zone and delegates via NS records (optional).

resource "aws_route53_zone" "management" {
  count = var.create_route53_hosted_zone ? 1 : 0
  name  = var.cf_default_root_domain
}

module "route53_delegation_cloudflare" {
  source = "../cluster-templates/dns-record"

  enable_cloudflare         = var.enable_cloudflare_delegation && var.create_route53_hosted_zone
  cloudflare_zone_id        = var.cloudflare_parent_zone_id
  cloudflare_record_name    = var.cloudflare_delegation_record_name
  cloudflare_record_type    = "NS"
  cloudflare_record_ttl     = 3600
  cloudflare_record_proxied = false
  cloudflare_record_comment = "Delegation to AWS Route53 (managed by Terraform)"
  cloudflare_record_values  = var.create_route53_hosted_zone ? aws_route53_zone.management[0].name_servers : []
}

output "route53_name_servers" {
  value       = var.create_route53_hosted_zone ? aws_route53_zone.management[0].name_servers : []
  description = "NS servers for the Route53 hosted zone (useful for Cloudflare delegation)"
}
