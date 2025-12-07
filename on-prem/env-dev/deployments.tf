# Deploying following resources:
## Microservices
# + TBD
## App Services
# + RabbitMQ
## Supporting Services
# + PGAdmin
# - Istio (Per Namespace)
# - Grafana & Prometheus (as Operators)
# + OpenSearch & OpenSearch Dashboard

################################ Microservice Resources ################################
# Deployed using ArgoCD

################################ App Service Resources ################################

# Deploying RabbitMQ
module "rabbitmq_helm" {
  source           = "../cluster-templates/helm-chart"
  chart_name       = "rabbitmq"
  chart_repository = "oci://registry-1.docker.io/bitnamicharts"
  chart            = "rabbitmq"
  namespace        = var.namespace
  chart_version    = var.rabbitmq_helm_version
  set_values = [
    { name = "image.repository", value = "bitnamilegacy/rabbitmq" }, # no longer provides latests version free of charge
    { name = "global.security.allowInsecureImages", value = "true" },
    { name = "auth.username", value = var.rabbitmq_username },
    { name = "auth.password", value = var.rabbitmq_password },
    { name = "auth.erlangCookie", value = var.rabbitmq_erlang_cookie },
    { name = "replicaCount", value = "1" },
    { name = "persistence.existingClaim", value = "rabbitmq-data-pvc" },
    { name = "podLabels.app", value = "rabbitmq" },
    { name = "service.type", value = "ClusterIP" },
    { name = "service.ports.amqp", value = "5672" },
    { name = "service.ports.management", value = "15672" },
    # Resource specifications
    { name = "resources.limits.memory", value = "512Mi" },
    { name = "resources.limits.cpu", value = "500m" },
    { name = "memoryHighWatermark.enabled", value = "true" },
    { name = "memoryHighWatermark.type", value = "absolute" },
    { name = "memoryHighWatermark.value", value = "256Mi" }
  ]
  depends_on = [kubernetes_namespace.env_dev, module.rabbitmq_data_pvc]
}



################################ Supporting Service Resources ################################

# Deploying PGAdmin
module "pgadmin_deployment" {
  source = "../cluster-templates/deployment"

  app_name       = "pgadmin"
  namespace      = var.namespace
  replicas       = 1
  selector_label = "pgadmin"
  app_image      = "dpage/pgadmin4:${var.pgadmin_image}"
  container_ports = [
    {
      name  = "web"
      value = 80
    }
  ]
  cpu_request    = "150m"
  memory_request = "256Mi"
  env_variable = [
    {
      name  = "PGADMIN_DEFAULT_EMAIL"
      value = var.pgadmin_email
    },
    {
      name  = "PGADMIN_DEFAULT_PASSWORD"
      value = var.pgadmin_password
    }
  ]
  volume_configs = [
    {
      name       = "pgadmin-data"
      mount_path = "/var/lib/pgadmin"
      pvc_name   = "pgadmin-data-pvc"
    }
  ]
  depends_on_resource = [kubernetes_namespace.env_dev, module.pgadmin_data_pvc]
}

# Deploying OpenSearch Cluster
module "opensearch_helm" {
  source           = "../cluster-templates/helm-chart"
  chart_name       = "opensearch"
  chart_repository = "https://opensearch-project.github.io/helm-charts/"
  chart            = "opensearch"
  namespace        = var.namespace
  chart_version    = var.opensearch_helm_version
  set_values = [
    { name = "clusterName", value = "opensearch-dev-cluster" },
    { name = "nodeGroup", value = "master" },
    { name = "replicas", value = "1" },
    { name = "minimumMasterNodes", value = "1" },
    # Resource specifications
    { name = "persistence.enabled", value = "true" },
    { name = "persistence.size", value = "10Gi" },
    { name = "persistence.storageClass", value = "longhorn" },
    { name = "resources.requests.cpu", value = "500m" },
    { name = "resources.requests.memory", value = "500Mi" },
    { name = "resources.limits.cpu", value = "1000m" },
    { name = "resources.limits.memory", value = "1Gi" },
    # Extra Variables
    { name = "DISABLE_INSTALL_DEMO_CONFIG", value = "true" },
    # Opensearch.yaml configs:
    { name = "config.\"opensearch\\.yml\"", value = var.opensearch_config_yaml }
  ]
  depends_on = [kubernetes_namespace.env_dev]
}
# Deploying OpenSearch Dashboard
module "opensearch_dashboard_helm" {
  source           = "../cluster-templates/helm-chart"
  chart_name       = "opensearch-dashboards"
  chart_repository = "https://opensearch-project.github.io/helm-charts/"
  chart            = "opensearch-dashboards"
  namespace        = var.namespace
  chart_version    = var.opensearch_dashboard_helm_version
  set_values = [
    { name = "opensearchHosts", value = "https://opensearch-dev-cluster.${var.namespace}.svc.${var.cluster_service_domain}:9200" },
    { name = "replicaCount", value = "1" },
    # Resource specifications
    { name = "resources.requests.cpu", value = "250m" },
    { name = "resources.requests.memory", value = "256Mi" },
    { name = "resources.limits.cpu", value = "500m" },
    { name = "resources.limits.memory", value = "512Mi" }
  ]
  depends_on = [kubernetes_namespace.env_dev, module.opensearch_helm]
}
