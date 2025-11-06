# Deploying following services:
# - CouchDB Service
# - PostgreSQL Service


# Deploying CouchDB Service
module "couchdb_service" {
  source = "../cluster-templates/service"

  service_name = "couchdb-service"
  namespace    = var.namespace
  app_selector = "couchdb"
  service_ports = [
    { name = "http", value = 5984, target_value = 5984, protocol = "TCP" },
  ]
  service_type        = "ClusterIP"
  depends_on_resource = module.couchdb_helm
}

# Deploying PostgreSQL Service
module "postgresql_service" {
  source = "../cluster-templates/service"

  service_name = "postgresql-service"
  namespace    = var.namespace
  app_selector = "postgresql"
  service_ports = [
    { name = "postgres", value = 5432, target_value = 5432, protocol = "TCP" }
  ]
  service_type        = "LoadBalancer"
  depends_on_resource = module.postgresql_deployment
}
