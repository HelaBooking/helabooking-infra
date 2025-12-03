
################################ Microservice Related DNS Records ################################
# Deploying Records - Cloudflare & NGINX Proxy Manager:
# - Frontend

# Deploying Frontend DNS Record
module "helabooking_frontend_dns" {
  source = "../cluster-templates/dns-record"

  # Cloudflare variables
  cf_dns_record_name  = "helabooking.${var.cf_default_root_domain}"
  cf_dns_record_value = var.cf_default_record_value

  # NGINX Proxy Manager variables
  nginx_proxy_manager_forward_protocol = "http"
  nginx_proxy_manager_forward_service  = "frontend-svc.${var.namespace}.${var.cluster_service_domain}"
  nginx_proxy_manager_forward_port     = 80
}

# Templ Deploying User API
module "helabooking_user_api_dns" {
  source = "../cluster-templates/dns-record"

  # Cloudflare variables
  cf_dns_record_name  = "user.api.${var.cf_default_root_domain}"
  cf_dns_record_value = var.cf_default_record_value

  # NGINX Proxy Manager variables
  nginx_proxy_manager_forward_protocol = "http"
  nginx_proxy_manager_forward_service  = "user-service-svc.${var.namespace}.${var.cluster_service_domain}"
  nginx_proxy_manager_forward_port     = 8081
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
}

################################ Supporting Service Related DNS Records ################################
# Deploying Records - Cloudflare & NGINX Proxy Manager:
# - Grafana
# - Prometheus
# - OpenSearch Dashboard


# Deploying Records - Cloudflare Only:
# - TBD
