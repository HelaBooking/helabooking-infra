# Templates to be used for NGINX Proxy Manager and Cloudflare DNS management

# Cloudflare DNS Record Management Module Template
resource "cloudflare_dns_record" "cloudflare_dns_record_template" {
  zone_id = var.cf_zone_id
  name    = var.cf_dns_record_name  # required
  content = var.cf_dns_record_value # required
  type    = var.cf_dns_record_type
  comment = var.cf_dns_record_comment
  ttl     = var.cf_dns_record_ttl
  proxied = var.cf_dns_record_proxied
}

# NGINX Proxy Manager - Certificate Template (let's encrypt)
resource "nginxproxymanager_certificate_letsencrypt" "proxy_certificate_template" {
  count        = var.enable_proxy ? 1 : 0 # Making this resource conditional
  domain_names = [var.cf_dns_record_name]

  letsencrypt_email = var.nginx_proxy_manager_letsencrypt_email
  letsencrypt_agree = true
  # also depends on the objects passed from the parent module, when a module is initialized using this template
  depends_on = [cloudflare_dns_record.cloudflare_dns_record_template, var.depends_on_resource]

}
# NGINX Proxy Manager - Proxy Host Template
resource "nginxproxymanager_proxy_host" "proxy_host_template" {
  count        = var.enable_proxy ? 1 : 0 # Making this resource conditional
  domain_names = [var.cf_dns_record_name]

  forward_scheme          = var.nginx_proxy_manager_forward_protocol # required
  forward_host            = var.nginx_proxy_manager_forward_service  # required
  forward_port            = var.nginx_proxy_manager_forward_port     # required
  advanced_config         = <<EOF
# Managed by Terraform
${var.nginx_proxy_manager_advanced_config}
EOF
  caching_enabled         = var.nginx_proxy_manager_caching_enabled
  allow_websocket_upgrade = var.nginx_proxy_manager_allow_websocket_upgrade # required
  block_exploits          = var.nginx_proxy_manager_block_exploits

  certificate_id = var.enable_proxy ? nginxproxymanager_certificate_letsencrypt.proxy_certificate_template[0].id : null # required

  ssl_forced      = var.nginx_proxy_manager_ssl_forced
  hsts_enabled    = var.nginx_proxy_manager_hsts_enabled
  hsts_subdomains = var.nginx_proxy_manager_hsts_subdomains
  http2_support   = var.nginx_proxy_manager_http2_support

  depends_on = [nginxproxymanager_certificate_letsencrypt.proxy_certificate_template, var.depends_on_resource]
}
