############################## DNS (Cloudflare + Route53) ##############################
# AWS is authoritative for the management subdomain hosted zone.
# Cloudflare remains authoritative for the parent zone and delegates via NS records (optional).

# Create Route53 hosted zone for aws services domain
resource "aws_route53_zone" "management_zone" {
  count = var.create_route53_hosted_zone ? 1 : 0
  name  = var.cf_default_root_domain
}

locals {
  enable_private_alb_alias = var.private_alb_dns_name != null && var.private_alb_zone_id != null
  enable_harbor_alb_alias  = var.harbor_alb_dns_name != null && var.harbor_alb_zone_id != null
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
  cloudflare_record_value_map = var.create_route53_hosted_zone ? {
    ns0 = aws_route53_zone.management_zone[0].name_servers[0]
    ns1 = aws_route53_zone.management_zone[0].name_servers[1]
    ns2 = aws_route53_zone.management_zone[0].name_servers[2]
    ns3 = aws_route53_zone.management_zone[0].name_servers[3]
  } : {}
}

output "route53_name_servers" {
  value       = var.create_route53_hosted_zone ? aws_route53_zone.management_zone[0].name_servers : []
  description = "NS servers for the Route53 hosted zone (useful for Cloudflare delegation)"
}


############################## Project DNS Records ##############################
# + Jenkins
# + Harbor
# + ArgoCD
# - Hashicorp Vault

module "jenkins_route53" {
  source = "../cluster-templates/dns-record"

  enable_route53      = local.enable_private_alb_alias
  route53_zone_id     = local.route53_zone_id
  route53_record_name = "jenkins.internal"
  route53_record_type = "A"
  route53_alias = local.enable_private_alb_alias ? {
    name                   = var.private_alb_dns_name
    zone_id                = var.private_alb_zone_id
    evaluate_target_health = true
  } : null
}

module "argocd_route53" {
  source = "../cluster-templates/dns-record"

  enable_route53      = local.enable_private_alb_alias
  route53_zone_id     = local.route53_zone_id
  route53_record_name = "argocd.internal"
  route53_record_type = "A"
  route53_alias = local.enable_private_alb_alias ? {
    name                   = var.private_alb_dns_name
    zone_id                = var.private_alb_zone_id
    evaluate_target_health = true
  } : null
}

module "harbor_route53" {
  source = "../cluster-templates/dns-record"

  enable_route53      = local.enable_harbor_alb_alias
  route53_zone_id     = local.route53_zone_id
  route53_record_name = "harbor"
  route53_record_type = "A"
  route53_alias = local.enable_harbor_alb_alias ? {
    name                   = var.harbor_alb_dns_name
    zone_id                = var.harbor_alb_zone_id
    evaluate_target_health = true
  } : null
}

