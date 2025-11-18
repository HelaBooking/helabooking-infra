############################## Cluster Management PVCs ##############################
# - NGINX Proxy Manager

# PVC for NGINX Proxy Manager
module "nginx_proxy_manager_data_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "nginx-proxy-manager-data-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "nginx-proxy-manager"
  access_modes        = ["ReadWriteMany"]
  storage_request     = "0.5Gi"
  depends_on_resource = [kubernetes_namespace.management, module.longhorn_helm]
}
module "nginx_proxy_manager_letsecrypt_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "nginx-proxy-manager-letsecrypt-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "nginx-proxy-manager"
  access_modes        = ["ReadWriteMany"]
  storage_request     = "0.5Gi"
  depends_on_resource = [kubernetes_namespace.management, module.longhorn_helm]
}


############################## Project PVCs ##############################
# - Jenkins

# PVC for Jenkins
module "jenkins_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "jenkins-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "jenkins"
  access_modes        = ["ReadWriteMany"]
  storage_request     = "10Gi"
  depends_on_resource = [kubernetes_namespace.management, module.longhorn_helm]
}

# PVCs for Harbor
module "harbor_registry_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "harbor-registry-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "harbor"
  access_modes        = ["ReadWriteMany"]
  storage_request     = "10Gi"
  depends_on_resource = [kubernetes_namespace.management, module.longhorn_helm]
}
module "harbor_database_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "harbor-database-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "harbor"
  access_modes        = ["ReadWriteMany"]
  storage_request     = "0.5Gi"
  depends_on_resource = [kubernetes_namespace.management, module.longhorn_helm]
}
module "harbor_jobservice_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "harbor-jobservice-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "harbor"
  access_modes        = ["ReadWriteMany"]
  storage_request     = "0.5Gi"
  depends_on_resource = [kubernetes_namespace.management, module.longhorn_helm]
}
module "harbor_redis_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "harbor-redis-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "harbor"
  access_modes        = ["ReadWriteMany"]
  storage_request     = "0.5Gi"
  depends_on_resource = [kubernetes_namespace.management, module.longhorn_helm]
}
module "harbor_trivy_pvc" {
  source = "../cluster-templates/pv-claim"

  pvc_name            = "harbor-trivy-pvc"
  namespace           = kubernetes_namespace.management.metadata[0].name
  app_selector        = "harbor"
  access_modes        = ["ReadWriteMany"]
  storage_request     = "2Gi"
  depends_on_resource = [kubernetes_namespace.management, module.longhorn_helm]
}
