# Deploying following resources:
## Microservices
# - TBD
## App Services
# - RabbitMQ
# - Redis
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

# Deploying Redis
module "redis_helm" {
  source           = "../cluster-templates/helm-chart"
  chart_name       = "redis"
  chart_repository = "https://charts.bitnami.com/bitnami"
  chart            = "redis"
  namespace        = var.namespace
  chart_version    = var.redis_helm_version
  set_values = [
    { name = "architecture", value = "standalone" },
    { name = "auth.enabled", value = "true" },
    { name = "auth.password", value = var.redis_password },
    { name = "master.persistence.existingClaim", value = "redis-data-pvc" },
    { name = "master.podLabels.app", value = "redis" },
    { name = "master.service.type", value = "ClusterIP" },
    { name = "master.service.port", value = "6379" },
    # Resource specifications
    { name = "master.resources.limits.memory", value = "256Mi" },
    { name = "master.resources.limits.cpu", value = "250m" }
  ]
  depends_on = [kubernetes_namespace.env_dev, module.redis_data_pvc]
}



################################ Supporting Service Resources ################################
