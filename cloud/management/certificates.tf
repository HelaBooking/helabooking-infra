locals {
  route53_zone_id = var.create_route53_hosted_zone ? aws_route53_zone.management_zone[0].zone_id : var.existing_route53_zone_id
}

resource "aws_acm_certificate" "wildcard" {
  domain_name               = "*.${var.cf_default_root_domain}"
  subject_alternative_names = [var.cf_default_root_domain]
  validation_method         = "DNS"
}

resource "aws_route53_record" "wildcard_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true

  zone_id = local.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for r in aws_route53_record.wildcard_validation : r.fqdn]
}

output "wildcard_certificate_arn" {
  value       = aws_acm_certificate_validation.wildcard.certificate_arn
  description = "ACM wildcard certificate ARN for use in ALB ingresses"
}
