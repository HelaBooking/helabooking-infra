################################ Microservice Related Services ################################
# Deploying following services:
# - TBD

################################ App Service Related Services ################################
# Deploying following services:
# + RabbitMQ Service (Deployed through Helm Chart - rabbitmq.env-dev.svc.cluster.local:5672)
# + Redis Service (Deployed through Helm Chart - redis.env-dev.svc.cluster.local:6379)

################################ Supporting Service Related Services ################################
# Deploying following services:
# + PGAdmin Service
# + Grafana Service & Prometheus Service (managed by Operator)
# + OpenSearch Service & OpenSearch Dashboard Service (managed by helm)
# - Istio (Related Services)

# Deploying PGAdmin Service
module "pgadmin_service" {
  source = "../cluster-templates/service"

  service_name = "pgadmin-service"
  namespace    = var.namespace
  app_selector = "pgadmin"
  service_ports = [
    { name = "http", value = 80, target_value = 80, protocol = "TCP" }
  ]
  service_type        = "ClusterIP"
  depends_on_resource = module.pgadmin_deployment
}
