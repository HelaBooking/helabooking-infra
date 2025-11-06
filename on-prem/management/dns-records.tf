# Deploying following dns-record resources:
# - NGINX Proxy Manager
# - Rancher Server
# - Longhorn UI

# Deploying NGINX Proxy Manager
module "nginx_proxy_manager_dns" {
  source = "../cluster-templates/dns-record"

  # Cloudflare variables
  cf_dns_record_name  = "proxy.${var.cf_default_root_domain}"
  cf_dns_record_value = var.cf_default_record_value

  # NGINX Proxy Manager variables
  nginx_proxy_manager_forward_protocol = "http"
  nginx_proxy_manager_forward_service  = "nginx-proxy-service.${var.namespace}.${var.cluster_service_domain}"
  nginx_proxy_manager_forward_port     = 81
}

# Deploying Rancher Server
# module "rancher_server_dns" {
#   source = "../cluster-templates/dns-record"

#   # Cloudflare variables
#   cf_dns_record_name  = "rancher.${var.cf_default_root_domain}"
#   cf_dns_record_value = var.cf_default_record_value

#   # NGINX Proxy Manager variables
#   nginx_proxy_manager_forward_protocol = "https"
#   nginx_proxy_manager_forward_service  = "traefik.${var.namespace}.${var.cluster_service_domain}"
#   nginx_proxy_manager_forward_port     = 443
# }

# Deploying Longhorn UI
module "longhorn_ui_dns" {
  source = "../cluster-templates/dns-record"

  # Cloudflare variables
  cf_dns_record_name  = "longhorn.${var.cf_default_root_domain}"
  cf_dns_record_value = var.cf_default_record_value

  # NGINX Proxy Manager variables
  nginx_proxy_manager_forward_protocol = "http"
  nginx_proxy_manager_forward_service  = "longhorn-frontend.longhorn-system.${var.cluster_service_domain}"
  nginx_proxy_manager_forward_port     = 80
}
