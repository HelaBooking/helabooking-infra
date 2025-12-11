################################ Microservice Related PVCs ################################
# TBD

################################ App Service Related PVCs ################################
# + RabbitMQ

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
# + PGAdmin
# + Grafana & Prometheus (managed by Operator)
# + OpenSearch & OpenSearch Dashboard (managed by helm)

# PVC for PGAdmin
module "pgadmin_data_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "pgadmin-data-pvc"
  namespace           = var.namespace
  app_selector        = "pgadmin"
  access_modes        = ["ReadWriteMany"]
  storage_request     = "1Gi"
  depends_on_resource = [kubernetes_namespace.env_dev]
}
