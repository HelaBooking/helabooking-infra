# Variables used in templates
variable "enable_proxy" {
  description = "Enable NGINX Proxy Manager for the DNS record"
  type        = bool
  default     = true
}
# Cloudflare DNS Record Variables
variable "cf_dns_record_name" {
  description = "Cloudflare DNS Record Name"
  type        = string
}
variable "cf_dns_record_value" {
  description = "Cloudflare DNS Record Value"
  type        = string
}
variable "cf_dns_record_type" {
  description = "Cloudflare DNS Record Type"
  type        = string
  default     = "CNAME"
}
variable "cf_dns_record_comment" {
  description = "Cloudflare DNS Record Comment"
  type        = string
  default     = "Managed by Terraform"
}
variable "cf_dns_record_ttl" {
  description = "Cloudflare DNS Record TTL"
  type        = number
  default     = 1 # Auto
}
variable "cf_dns_record_proxied" {
  description = "Cloudflare DNS Record Proxied"
  type        = bool
  default     = false
}

# NGINX Proxy Manager - Certificate Variables
variable "nginx_proxy_manager_letsencrypt_email" {
  description = "Email for Let's Encrypt certificate registration"
  type        = string
  default     = "gvinura@gmail.com"
}
output "letsecrypt_issued_certificate_id" {
  value = var.enable_proxy ? nginxproxymanager_certificate_letsencrypt.proxy_certificate_template[0].id : null
}

# NGINX Proxy Manager - Proxy Host Variables
variable "nginx_proxy_manager_forward_protocol" {
  description = "Protocol to forward requests (http or https)"
  type        = string
  default     = "http"
}
variable "nginx_proxy_manager_forward_service" {
  description = "Service name or IP address to forward requests to"
  type        = string
  default     = "localhost"
}
variable "nginx_proxy_manager_forward_port" {
  description = "Port number to forward requests to"
  type        = number
  default     = 80
}
variable "nginx_proxy_manager_advanced_config" {
  description = "Advanced configuration for the proxy host"
  type        = string
  default     = ""
}
variable "nginx_proxy_manager_caching_enabled" {
  description = "Enable caching for the proxy host"
  type        = bool
  default     = false
}
variable "nginx_proxy_manager_allow_websocket_upgrade" {
  description = "Allow WebSocket upgrades"
  type        = bool
  default     = false
}
variable "nginx_proxy_manager_block_exploits" {
  description = "Enable exploit blocking"
  type        = bool
  default     = true
}
variable "nginx_proxy_manager_additional_locations" {
  description = "Additional location blocks for the proxy host"
  type = list(object({
    path           = string
    forward_scheme = string
    forward_host   = string
    forward_port   = number
  }))
  default = []
}
variable "nginx_proxy_manager_ssl_forced" {
  description = "Force SSL for the proxy host"
  type        = bool
  default     = true
}
variable "nginx_proxy_manager_hsts_enabled" {
  description = "Enable HSTS"
  type        = bool
  default     = false
}
variable "nginx_proxy_manager_hsts_subdomains" {
  description = "Include subdomains in HSTS"
  type        = bool
  default     = false
}
variable "nginx_proxy_manager_http2_support" {
  description = "Enable HTTP/2 support"
  type        = bool
  default     = true
}
variable "depends_on_resource" {
  description = "Resource that this service depends on"
  type        = any
  default     = null
}
