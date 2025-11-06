# Deploying following services:
# - NGINX Proxy Service

# Deploying NGINX Proxy Manager Ingress Service
module "nginx_ingress_service" {
  source = "../cluster-templates/service"

  service_name = "nginx-proxy-service"
  namespace    = kubernetes_namespace.management.metadata[0].name
  app_selector = "nginx-proxy-manager"
  service_ports = [
    { name = "http", value = 80, target_value = 80, protocol = "TCP" },
    { name = "https", value = 443, target_value = 443, protocol = "TCP" },
    { name = "admin-ui", value = 81, target_value = 81, protocol = "TCP" }
  ]
  service_type        = "LoadBalancer"
  depends_on_resource = module.nginx_proxy_deployment
}
