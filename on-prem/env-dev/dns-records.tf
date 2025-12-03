
################################ Microservice Related DNS Records ################################
# Deploying Records - Cloudflare & NGINX Proxy Manager:
# - Frontend

# Deploying Ingress DNS Record
module "helabooking_ingress_dns" {
  source = "../cluster-templates/dns-record"

  # Cloudflare variables
  cf_dns_record_name  = "hela.${var.cf_default_root_domain}"
  cf_dns_record_value = var.cf_default_record_value

  # NGINX Proxy Manager variables
  nginx_proxy_manager_forward_protocol = "https"
  nginx_proxy_manager_forward_service  = "traefik.${var.namespace}.${var.cluster_service_domain}"
  nginx_proxy_manager_forward_port     = 443
}


################################ App Service Related DNS Records ################################
# Deploying Records - Cloudflare & NGINX Proxy Manager:
# - RabbitMQ

# Deploying RabbitMQ DNS Record
module "rabbitmq_dns" {
  source = "../cluster-templates/dns-record"

  # Cloudflare variables
  cf_dns_record_name  = "rabbitmq.${var.cf_default_root_domain}"
  cf_dns_record_value = var.cf_default_record_value

  # NGINX Proxy Manager variables
  nginx_proxy_manager_forward_protocol = "http"
  nginx_proxy_manager_forward_service  = "rabbitmq.${var.namespace}.${var.cluster_service_domain}"
  nginx_proxy_manager_forward_port     = 15672

  depends_on_resource = [module.helabooking_ingress_dns] # To prevent 500 error when letsencrypt tries to create mutiple certificates
}

################################ Supporting Service Related DNS Records ################################
# Deploying Records - Cloudflare & NGINX Proxy Manager:
# - PGAdmin
# - Grafana
# - Prometheus
# - OpenSearch Dashboard


# Deploying Records - Cloudflare Only:
# - TBD


# Deploying PGAdmin DNS Record
module "pgadmin_dns" {
  source = "../cluster-templates/dns-record"

  # Cloudflare variables
  cf_dns_record_name  = "pgadmin.${var.cf_default_root_domain}"
  cf_dns_record_value = var.cf_default_record_value

  # NGINX Proxy Manager variables
  nginx_proxy_manager_forward_protocol = "http"
  nginx_proxy_manager_forward_service  = "pgadmin-service.${var.namespace}.${var.cluster_service_domain}"
  nginx_proxy_manager_forward_port     = 80

  depends_on_resource = [module.rabbitmq_dns] # To prevent 500 error when letsencrypt tries to create mutiple certificates
}
