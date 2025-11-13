############################## Cluster Management DNS Records ##############################
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
#
#   depends_on_resource = [module.nginx_proxy_manager_dns] # To prevent 500 error when letsencrypt tries to create mutiple certificates
# }

# Deploying Longhorn UI
module "longhorn_ui_dns" {
  source = "../cluster-templates/dns-record"

  # Cloudflare variables
  cf_dns_record_name  = "longhorn.${var.cf_default_root_domain}"
  cf_dns_record_value = "192.168.1.100" # Only local network access
  cf_dns_record_type  = "A"

  # NGINX Proxy Manager variables
  nginx_proxy_manager_forward_protocol = "http"
  nginx_proxy_manager_forward_service  = "longhorn-frontend.longhorn-system.${var.cluster_service_domain}"
  nginx_proxy_manager_forward_port     = 80

  depends_on_resource = [module.nginx_proxy_manager_dns] # To prevent 500 error when letsencrypt tries to create mutiple certificates
}


############################## Project DNS Records ##############################
# - Jenkins
# - Harbor
# - ArgoCD
# - Hashicorp Vault

# Deploying Jenkins DNS Record
module "jenkins_dns" {
  source = "../cluster-templates/dns-record"

  # Cloudflare variables
  cf_dns_record_name  = "jenkins.${var.cf_default_root_domain}"
  cf_dns_record_value = var.cf_default_record_value

  # NGINX Proxy Manager variables
  nginx_proxy_manager_forward_protocol = "http"
  nginx_proxy_manager_forward_service  = "jenkins.${var.namespace}.${var.cluster_service_domain}"
  nginx_proxy_manager_forward_port     = 8080

  depends_on_resource = [module.longhorn_ui_dns] # To prevent 500 error when letsencrypt tries to create mutiple certificates
}
