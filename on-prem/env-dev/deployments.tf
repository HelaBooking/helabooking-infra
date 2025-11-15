# Deploying following resources:
## App Services
# - RabbitMQ
# - Redis
## Supporting Services
# - Istio (Per Namespace)
# - Grafana & Prometheus
# - OpenSearch & OpenSearch Dashboard



# Deploying CouchDB using Helm
module "couchdb_helm" {
  source = "../cluster-templates/helm-chart"

  chart_name       = "couchdb"
  chart_repository = "https://apache.github.io/couchdb-helm/"
  chart            = "couchdb"
  namespace        = var.namespace
  chart_version    = var.couchdb_helm_version
  set_values = [
    { name = "couchdbConfig.couchdb.uuid", value = var.couchdb_uuid },
    { name = "adminUsername", value = var.couchdb_username },
    { name = "adminPassword", value = var.couchdb_password },
    { name = "clusterSize", value = "1" },
    # Volume configurations
    { name = "persistentVolume.enabled", value = "true" },
    { name = "persistentVolume.size", value = "1Gi" },
    { name = "persistentVolume.storageClass", value = "longhorn-sc" },

    # Specific configurations
    { name = "couchdbConfig.chttpd.bind_address", value = "0.0.0.0" },
    { name = "couchdbConfig.httpd.bind_address", value = "0.0.0.0" },
    { name = "couchdbConfig.prometheus.bind_address", value = "0.0.0.0" },
    { name = "couchdbConfig.chttpd.enable_cors", value = "true" },
    { name = "couchdbConfig.cors.origins", value = "*" },
    { name = "podLabels.app", value = "couchdb" },
    { name = "service.enabled", value = "false" },
  ]
  depends_on = [kubernetes_namespace.env_dev]
}

# Deploying PostgreSQL
module "postgresql_deployment" {
  source = "../cluster-templates/deployment"

  app_name       = "postgresql"
  namespace      = var.namespace
  replicas       = 1
  selector_label = "postgresql"
  app_image      = "postgres:${var.postgresql_image}"
  container_ports = [
    {
      name  = "postgres"
      value = 5432
    }
  ]
  cpu_request    = "250m"
  memory_request = "256Mi"
  env_variable = [
    {
      name  = "POSTGRES_USER"
      value = var.postgresql_username
    },
    {
      name  = "POSTGRES_PASSWORD"
      value = var.postgresql_password
    },
    {
      name  = "POSTGRES_DB"
      value = var.postgresql_database
    },
    {
      name  = "PGDATA"
      value = "/var/lib/postgresql/data/pgdata"
    }
  ]
  volume_configs = [
    {
      name       = "postgresql-data"
      mount_path = "/var/lib/postgresql/data/"
      pvc_name   = "postgresql-data-pvc"
    }
  ]
  depends_on_resource = [kubernetes_namespace.env_dev, module.postgresql_data_pvc]
}
