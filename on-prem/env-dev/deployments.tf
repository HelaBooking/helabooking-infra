# Deploying following resources:
## Microservices
# - TBD
## App Services
# + RabbitMQ
## Supporting Services
# - Istio (Per Namespace)
# - Grafana & Prometheus (as Operators)
# - OpenSearch & OpenSearch Dashboard

################################ Microservice Resources ################################
# TBD

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
# TBD
