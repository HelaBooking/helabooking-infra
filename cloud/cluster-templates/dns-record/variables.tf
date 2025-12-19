############################## Route53 (optional) ##############################
variable "enable_route53" {
  description = "If true, manage a Route53 record"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
  default     = null
}

variable "route53_record_name" {
  description = "Route53 record name (relative to the hosted zone or FQDN)"
  type        = string
  default     = null
}

variable "route53_record_type" {
  description = "Route53 record type (A, AAAA, CNAME, TXT, etc.)"
  type        = string
  default     = "A"
}

variable "route53_record_ttl" {
  description = "Route53 record TTL in seconds (used for non-alias records)"
  type        = number
  default     = 300
}

variable "route53_record_values" {
  description = "Route53 record values for non-alias records"
  type        = list(string)
  default     = []
}

variable "route53_alias" {
  description = "Optional Route53 alias target (e.g., ALB). If provided, an alias record is created. Example: { name = \"dualstack.my-alb.amazonaws.com\", zone_id = \"Z35SXDOTRQ7X7K\", evaluate_target_health = true }"
  type = object({
    name                   = string
    zone_id                = string
    evaluate_target_health = optional(bool)
  })
  default = null
}

############################## Cloudflare (optional) ##############################
variable "enable_cloudflare" {
  description = "If true, manage one or more Cloudflare DNS records"
  type        = bool
  default     = false
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  default     = null
}

variable "cloudflare_record_name" {
  description = "Cloudflare DNS record name (relative label or FQDN depending on zone)"
  type        = string
  default     = null
}

variable "cloudflare_record_type" {
  description = "Cloudflare DNS record type (A, CNAME, NS, TXT, etc.)"
  type        = string
  default     = "CNAME"
}

variable "cloudflare_record_ttl" {
  description = "Cloudflare TTL. Use 1 for 'Auto'"
  type        = number
  default     = 1
}

variable "cloudflare_record_proxied" {
  description = "Whether Cloudflare should proxy the record"
  type        = bool
  default     = false
}

variable "cloudflare_record_comment" {
  description = "Cloudflare record comment"
  type        = string
  default     = "Managed by Terraform"
}

variable "cloudflare_record_values" {
  description = "Cloudflare record contents. If multiple values are provided (e.g., NS delegation), one record per value is created. For single-value records, provide a single item."
  type        = list(string)
  default     = []
}

variable "cloudflare_record_value_map" {
  description = "Optional map of Cloudflare record contents keyed by stable identifiers. Prefer this when values are only known after apply (e.g., Route53 name_servers) to keep for_each keys static."
  type        = map(string)
  default     = {}
}

############################## Outputs ##############################
output "route53_fqdn" {
  value = try(aws_route53_record.route53_alias[0].fqdn, aws_route53_record.route53_standard[0].fqdn, null)
}

output "cloudflare_record_ids" {
  value = try([for r in cloudflare_dns_record.cloudflare_record : r.id], [])
}

output "cloudflare_record_names" {
  value = try([for r in cloudflare_dns_record.cloudflare_record : r.name], [])
}
