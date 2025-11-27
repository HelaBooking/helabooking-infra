################################ Microservice Related PVCs ################################
# TBD

################################ App Service Related PVCs ################################
# - RabbitMQ

# PVC for RabbitMQ Server
module "rabbitmq_data_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "rabbitmq-data-pvc"
  namespace           = var.namespace
  app_selector        = "rabbitmq"
  access_modes        = ["ReadWriteMany"]
  storage_request     = "1Gi"
  depends_on_resource = [kubernetes_namespace.env_dev]
}

################################ Supporting Service Related PVCs ################################
# - Grafana
# - Prometheus
# - OpenSearch
# - OpenSearch Dashboard
