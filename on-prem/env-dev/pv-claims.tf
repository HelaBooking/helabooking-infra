# PVC used by the Development environment applications

# PVC for CouchDB Server
# This is managed by CouchDB Helm Chart - PVC name: database-storage-couchdb-couchdb-0

# PVC for PostgreSQL Server
module "postgresql_data_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "postgresql-data-pvc"
  namespace           = var.namespace
  app_selector        = "postgresql"
  access_modes        = ["ReadWriteMany"]
  storage_request     = "1Gi"
  depends_on_resource = [kubernetes_namespace.env_dev]
}
