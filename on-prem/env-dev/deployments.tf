# Deploying following resources:
## Microservices
# + Deployed using ArgoCD
## App Services
# + RabbitMQ
## Supporting Services
# + PGAdmin
# + Istio (Per Namespace)
# + Kiali Dashboard (Istio monitoring)
# + Grafana & Prometheus (as Operators)
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
  replicas       = var.enable_pgadmin ? 1 : 0 # Enable or Disable PGAdmin Deployment
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
  count            = var.enable_opensearch ? 1 : 0 # Enable or Disable OpenSearch Deployment
  set_values = [
    { name = "clusterName", value = "opensearch-dev-cluster" },
    { name = "nodeGroup", value = "master" },
    { name = "replicas", value = "1" },
    { name = "minimumMasterNodes", value = "1" },
    { name = "service.httpPortName", value = "https" },
    # Resource specifications
    { name = "nodeSelector.kubernetes\\.io/hostname", value = "pico-node" },
    { name = "persistence.enabled", value = "true" },
    { name = "persistence.size", value = "10Gi" },
    { name = "persistence.storageClass", value = "longhorn" },
    { name = "resources.requests.cpu", value = "500m" },
    { name = "resources.requests.memory", value = "500Mi" },
    { name = "resources.limits.cpu", value = "1000m" },
    { name = "resources.limits.memory", value = "1Gi" },
    # Extra Variables
    { name = "extraEnvs[0].name", value = "OPENSEARCH_INITIAL_ADMIN_PASSWORD" },
    { name = "extraEnvs[0].value", value = var.opensearch_admin_password },

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
  count            = var.enable_opensearch_dashboard && var.enable_opensearch ? 1 : 0 # Enable or Disable OpenSearch Dashboard Deployment
  set_values = [
    { name = "opensearchHosts", value = "https://opensearch-cluster-master.${var.namespace}.${var.cluster_service_domain}:9200" },
    { name = "replicaCount", value = "1" },
    # Resource specifications
    { name = "nodeSelector.kubernetes\\.io/hostname", value = "pico-node" },
    { name = "resources.requests.cpu", value = "250m" },
    { name = "resources.requests.memory", value = "256Mi" },
    { name = "resources.limits.cpu", value = "500m" },
    { name = "resources.limits.memory", value = "512Mi" }
  ]
  depends_on = [kubernetes_namespace.env_dev, module.opensearch_helm]
}

# Deploying Prometheus & Grafana Operators using Helm
module "kube_prometheus_stack_helm" {
  source           = "../cluster-templates/helm-chart"
  chart_name       = "kube-prometheus-stack"
  chart_repository = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.namespace
  chart_version    = var.kube_prometheus_stack_helm_version
  # custom values
  custom_values = var.prometheus_grafana_values

  set_values = [
    { name = "grafana.adminPassword", value = var.grafana_admin_password },
    { name = "grafana.service.type", value = "ClusterIP" },
    # Enable or Disable Services
    { name = "grafana.enabled", value = tostring(var.enable_grafana) },
    { name = "prometheus.enabled", value = tostring(var.enable_prometheus) },
    { name = "alertmanager.enabled", value = tostring(var.enable_prometheus) },
    # Resource specs
    { name = "prometheus.prometheusSpec.resources.requests.cpu", value = "200m" },
    { name = "prometheus.prometheusSpec.resources.requests.memory", value = "512Mi" },
    { name = "prometheus.prometheusSpec.resources.limits.cpu", value = "500m" },
    { name = "prometheus.prometheusSpec.resources.limits.memory", value = "1Gi" },
    { name = "prometheusOperator.resources.requests.cpu", value = "100m" },
    { name = "prometheusOperator.resources.requests.memory", value = "256Mi" },
    { name = "prometheusOperator.resources.limits.cpu", value = "400m" },
    { name = "prometheusOperator.resources.limits.memory", value = "1Gi" },
    { name = "alertmanager.alertmanagerSpec.resources.requests.cpu", value = "100m" },
    { name = "alertmanager.alertmanagerSpec.resources.requests.memory", value = "200Mi" },
    { name = "alertmanager.alertmanagerSpec.resources.limits.cpu", value = "500m" },
    { name = "alertmanager.alertmanagerSpec.resources.limits.memory", value = "400Mi" },
    { name = "grafana.resources.requests.cpu", value = "100m" },
    { name = "grafana.resources.requests.memory", value = "512Mi" },
    { name = "grafana.resources.limits.cpu", value = "500m" },
    { name = "grafana.resources.limits.memory", value = "1Gi" },
    # Storage specs
    { name = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage", value = "10Gi" },
    { name = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName", value = "longhorn" },
    { name = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage", value = "500Mi" },
    { name = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName", value = "longhorn" }
  ]
  depends_on = [kubernetes_namespace.env_dev]
}

# Deploying Istio
# Deploying Istiod for the Namespace
module "istiod_dev_helm" {
  source           = "../cluster-templates/helm-chart"
  chart_name       = "istiod-dev"
  chart_repository = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  namespace        = var.istio_namespace
  chart_version    = var.istiod_helm_version

  set_values = [
    { name = "revision", value = "dev" },
    { name = "pilot.resources.requests.cpu", value = "100m" },
    { name = "pilot.resources.requests.memory", value = "128Mi" }
  ]
}
# Deploying Istio Ingress Gateway
module "istio_ingress_gateway_dev_helm" {
  source           = "../cluster-templates/helm-chart"
  chart_name       = "istio-ingress-dev"
  chart_repository = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  namespace        = var.istio_namespace
  chart_version    = var.istiogateway_helm_version

  set_values = [
    { name = "revision", value = "dev" },
    { name = "resources.limits.cpu", value = "500m" },
    { name = "resources.limits.memory", value = "512Mi" },

    # Network & Service Settings
    { name = "service.type", value = "ClusterIP" },
    { name = "autoscaling.enabled", value = "false" },

    # This gateway will select label: istio: ingressgateway-dev
    { name = "labels.istio", value = "ingressgateway-dev-public" },
    { name = "labels.app", value = "istio-ingressgateway-dev" }
  ]
  depends_on = [module.istiod_dev_helm]
}
# Deploying Kiali Dashboard
module "kiali_helm" {
  source           = "../cluster-templates/helm-chart"
  chart_name       = "kiali-server"
  chart_repository = "https://kiali.org/helm-charts"
  chart            = "kiali-server"
  namespace        = var.istio_namespace
  chart_version    = var.kiali_helm_version

  set_values = [
    { name = "instance_name", value = "kiali" },
    { name = "deployment.replicas", value = var.enable_kiali_dashboard ? "1" : "0" }, # Scale down when not in use

    { name = "auth.strategy", value = "anonymous" }, # No authentication for dev environment
    { name = "deployment.cluster_wide_access", value = "false" },
    { name = "deployment.discovery_selectors.default[0].matchLabels.istio\\.io/rev", value = "dev" },
    { name = "deployment.discovery_selectors.default[1].matchLabels.kubernetes\\.io/metadata\\.name", value = "istio-system" },

    { name = "external_services.prometheus.url", value = "http://prometheus-dev-prometheus.env-dev.svc.cluster.local:9090" },
    { name = "server.port", value = "20001" },
    { name = "server.web_root", value = "/" },

    # Resource specifications
    { name = "deployment.resources.requests.cpu", value = "50m" },
    { name = "deployment.resources.requests.memory", value = "100Mi" },
    { name = "deployment.resources.limits.cpu", value = "500m" },
    { name = "deployment.resources.limits.memory", value = "500Mi" },
  ]

  depends_on = [module.istiod_dev_helm, kubernetes_namespace.env_dev]
}
