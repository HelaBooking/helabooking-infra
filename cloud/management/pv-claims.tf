############################## Cluster Management PVCs ##############################
# - None

############################## Project PVCs ##############################
# + Jenkins
# + Harbor


# PVC for Jenkins
module "jenkins_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "jenkins-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "jenkins"
  access_modes        = ["ReadWriteOnce"]
  storage_request     = "20Gi"
  depends_on_resource = [kubernetes_namespace.management]
}

# PVCs for Harbor
module "harbor_registry_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "harbor-registry-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "harbor"
  access_modes        = ["ReadWriteOnce"]
  storage_request     = "50Gi"
  depends_on_resource = [kubernetes_namespace.management]
}
module "harbor_database_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "harbor-database-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "harbor"
  access_modes        = ["ReadWriteOnce"]
  storage_request     = "5Gi"
  depends_on_resource = [kubernetes_namespace.management]
}
module "harbor_jobservice_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "harbor-jobservice-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "harbor"
  access_modes        = ["ReadWriteOnce"]
  storage_request     = "2Gi"
  depends_on_resource = [kubernetes_namespace.management]
}
module "harbor_redis_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "harbor-redis-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "harbor"
  access_modes        = ["ReadWriteOnce"]
  storage_request     = "2Gi"
  depends_on_resource = [kubernetes_namespace.management]
}
module "harbor_trivy_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "harbor-trivy-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "harbor"
  access_modes        = ["ReadWriteOnce"]
  storage_request     = "10Gi"
  depends_on_resource = [kubernetes_namespace.management]
}
