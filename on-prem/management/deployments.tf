# Deploying following cluster resources:
# + Traefik
# + Cert-Manager
# - Rancher Server (Skipped due to resource constraints)
# + Longhorn & Storage Class
# + NGINX Proxy Manager

# Deploying Project Common Resources:
# + Jenkins + Trivy (Vulnerability Scanning)
# + Harbor
# - ArgoCD
# - Fluent Bit
# - Hashicorp Vault

# - WSO2 Identity Server (Optional)
# - Ansible (Outside of cluster)


################################ Cluster Resources ################################

# Deploying Traefik Ingress Controller (Internal only) using helm-chart template
module "traefik_helm" {
  source = "../cluster-templates/helm-chart"

  chart_name       = "traefik"
  chart_repository = "https://helm.traefik.io/traefik"
  chart            = "traefik"
  namespace        = kubernetes_namespace.management.metadata[0].name
  chart_version    = var.traefik_version
  set_values = [
    { name = "dashboard.enabled", value = "true" },
    { name = "ports.websecure.tls.enabled", value = "true" },
    { name = "ports.websecure.port", value = "443" },
    { name = "ports.web.port", value = "80" },
    { name = "service.type", value = "ClusterIP" },
    { name = "replicas", value = "1" },
    { name = "resources.requests.cpu", value = "100m" },
    { name = "resources.requests.memory", value = "50Mi" }
  ]
  depends_on_resource = kubernetes_namespace.management
}
# Deploying Cert-Manager
module "cert_manager_helm" {
  source = "../cluster-templates/helm-chart"

  chart_name       = "cert-manager"
  chart_repository = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = kubernetes_namespace.cert_manager.metadata[0].name
  chart_version    = var.cert_manager_version
  set_values = [
    { name = "crds.enabled", value = "true" },
    { name = "crds.keep", value = "true" },
    { name = "replicaCount", value = "1" },
    { name = "resources.limits.cpu", value = "400m" },
    { name = "resources.limits.memory", value = "256Mi" },
    { name = "resources.requests.cpu", value = "100m" },
    { name = "resources.requests.memory", value = "100Mi" }
  ]
  depends_on_resource = [kubernetes_namespace.cert_manager, module.traefik_helm]
}
# Deploying Rancher Server
# module "rancher_helm" {
#   source = "../cluster-templates/helm-chart"

#   chart_name       = "rancher"
#   chart_repository = "https://releases.rancher.com/server-charts/latest"
#   chart            = "rancher"
#   namespace        = kubernetes_namespace.rancher.metadata[0].name
#   chart_version    = var.rancher_version
#   set_values = [
#     { name = "hostname", value = var.rancher_hostname },
#     { name = "replicas", value = "1" },
#     { name = "ingress.tls.source", value = "rancher" },
#     { name = "resources.requests.cpu", value = "400m" },
#     { name = "resources.requests.memory", value = "256Mi" }
#   ]
#   depends_on_resource = [kubernetes_namespace.rancher, module.cert_manager_helm, module.traefik_helm]
# }

# Deploying Longhorn
module "longhorn_helm" {
  source = "../cluster-templates/helm-chart"

  chart_name       = "longhorn"
  chart_repository = "https://charts.longhorn.io"
  chart            = "longhorn"
  namespace        = kubernetes_namespace.longhorn.metadata[0].name
  chart_version    = var.longhorn_version
  set_values = [
    { name = "defaultSettings.defaultDataPath", value = "/longhorn" },
    { name = "csi.attacherReplicaCount", value = "1" },
    { name = "csi.provisionerReplicaCount", value = "1" },
    { name = "csi.resizerReplicaCount", value = "1" },
    { name = "csi.snapshotterReplicaCount", value = "1" },
    { name = "longhornUI.replicas", value = "1" },
    { name = "resources.requests.cpu", value = "200m" },
    { name = "resources.requests.memory", value = "128Mi" },

    # prevent Helm from creating its own StorageClass
    { name = "defaultSettings.createDefaultDiskLabeledNodes", value = "false" },
    { name = "defaultSettings.createDefaultStorageClass", value = "false" },
  ]
  depends_on_resource = [kubernetes_namespace.longhorn]
}
# Deploying Longhorn Storage Class
resource "kubernetes_storage_class" "longhorn_sc" {
  metadata {
    name = "longhorn-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "driver.longhorn.io"
  reclaim_policy      = "Retain"
  volume_binding_mode = "Immediate"
  parameters = {
    numberOfReplicas          = "2"
    staleReplicaTimeout       = "30"
    fromBackup                = ""
    fsType                    = "ext4"
    dataLocality              = "disabled"
    unmapMarkSnapChainRemoved = "ignored"
    disableRevisionCounter    = "true"
    dataEngine                = "v1"
    backupTargetName          = "default"
  }
  allow_volume_expansion = true
  depends_on             = [kubernetes_namespace.longhorn, module.longhorn_helm]
}
# Deploying NGINX Proxy Manager
module "nginx_proxy_deployment" {
  source = "../cluster-templates/deployment"

  app_name       = "nginx-proxy-manager"
  namespace      = kubernetes_namespace.management.metadata[0].name
  replicas       = 1
  selector_label = "nginx-proxy-manager"
  app_image      = "jc21/nginx-proxy-manager:${var.nginx_proxy_manager_version}"
  container_ports = [
    {
      name  = "admin-ui"
      value = 81
    },
    {
      name  = "http"
      value = 80
    },
    {
      name  = "https"
      value = 443
    }
  ]
  cpu_request    = "150m"
  memory_request = "128Mi"
  volume_configs = [
    {
      name       = "data",
      pvc_name   = "nginx-proxy-manager-data-pvc",
      mount_path = "/data"
    },
    {
      name       = "letsencrypt",
      pvc_name   = "nginx-proxy-manager-letsecrypt-pvc",
      mount_path = "/etc/letsencrypt"
    }
  ]
  depends_on_resource = [kubernetes_namespace.management, module.nginx_proxy_manager_data_pvc, module.nginx_proxy_manager_letsecrypt_pvc, module.longhorn_helm]
}


################################ Project Resources ################################
# Deploying Jenkins
module "jenkins_helm" {
  source = "../cluster-templates/helm-chart"

  chart_name       = "jenkins"
  chart_repository = "https://charts.jenkins.io"
  chart            = "jenkins"
  namespace        = kubernetes_namespace.management.metadata[0].name
  chart_version    = var.jenkins_version
  set_values = [
    { name = "controller.admin.password", value = var.jenkins_admin_password },
    { name = "controller.serviceType", value = "ClusterIP" },
    { name = "controller.resources.limits.cpu", value = "1500m" },
    { name = "controller.resources.limits.memory", value = "2Gi" },
    { name = "persistence.existingClaim", value = "jenkins-pvc" },
    { name = "controller.jenkinsUrl", value = "https://jenkins.${var.cf_default_root_domain}/" },
    # Agent configs
    { name = "agent.nodeSelector.kubernetes\\.io/hostname", value = var.jenkins_agent_node_selector_hostname },
    { name = "agent.podName", value = "jenkins-agent" },
    { name = "agent.idleMinutes", value = "10080" }, # 7 days
    { name = "agent.hostNetworking", value = "false" },
    { name = "agent.privileged", value = "true" },
    { name = "agent.runAsUser", value = "0" },
    { name = "agent.runAsGroup", value = "0" },
    { name = "agent.resources.limits.cpu", value = "1000m" },
    { name = "agent.resources.limits.memory", value = "1Gi" },
    # Additional Containers - BuildKit
    { name = "agent.additionalContainers", value_list = [var.jenkins_buildkit_container] },
    { name = "agent.volumes[0].name", value = "workspace-volume" },
    { name = "agent.volumes[0].emptyDir", value = "{}" },
    { name = "agent.volumes[1].name", value = "buildkit-socket" },
    { name = "agent.volumes[1].emptyDir", value = "{}" },
    # Plugins
    {
      name = "controller.additionalPlugins",
      value_list = [
        "github-branch-source:1917.v9ee8a_39b_3d0d",
        "ansicolor:1.0.6"
      ]
    },
    # Config as Code (JCasC) scripts
    { name = "controller.JCasC.configScripts.git-creds", value = var.jenkins_git_credentials },
    { name = "controller.JCasC.configScripts.aws-creds", value = var.jenkins_aws_credentials },
    { name = "controller.JCasC.configScripts.harbor-creds", value = var.harbor_credentials }
  ]
  depends_on_resource = [kubernetes_namespace.management, module.traefik_helm, module.longhorn_helm, module.jenkins_pvc]
}

# Deploying Harbor
module "harbor_helm" {
  source = "../cluster-templates/helm-chart"

  chart_name       = "harbor"
  chart_repository = "https://helm.goharbor.io"
  chart            = "harbor"
  namespace        = kubernetes_namespace.management.metadata[0].name
  chart_version    = var.harbor_version
  set_values = [
    { name = "imagePullPolicy", value = "Always" },
    { name = "externalURL", value = "https://harbor.${var.cf_default_root_domain}" },
    { name = "expose.ingress.hosts.core", value = "harbor.${var.cf_default_root_domain}" },
    { name = "harborAdminPassword", value = var.harbor_admin_password },
    # Force to schedule on amd64 node, since harbor images are not available for arm64 architecture
    { name = "nodeSelector.kubernetes\\.io/hostname", value = "galaxy-node" },
    { name = "nginx.nodeSelector.kubernetes\\.io/hostname", value = "galaxy-node" },
    { name = "portal.nodeSelector.kubernetes\\.io/hostname", value = "galaxy-node" },
    { name = "core.nodeSelector.kubernetes\\.io/hostname", value = "galaxy-node" },
    { name = "jobservice.nodeSelector.kubernetes\\.io/hostname", value = "galaxy-node" },
    { name = "registry.nodeSelector.kubernetes\\.io/hostname", value = "galaxy-node" },
    { name = "trivy.nodeSelector.kubernetes\\.io/hostname", value = "galaxy-node" },
    { name = "database.internal.nodeSelector.kubernetes\\.io/hostname", value = "galaxy-node" },
    { name = "redis.internal.nodeSelector.kubernetes\\.io/hostname", value = "galaxy-node" },
    { name = "exporter.nodeSelector.kubernetes\\.io/hostname", value = "galaxy-node" },
    # PVCs used in harbor
    { name = "persistence.persistentVolumeClaim.registry.existingClaim", value = "harbor-registry-pvc" },
    { name = "persistence.persistentVolumeClaim.database.existingClaim", value = "harbor-database-pvc" },
    { name = "persistence.persistentVolumeClaim.jobservice.jobLog.existingClaim", value = "harbor-jobservice-pvc" },
    { name = "persistence.persistentVolumeClaim.redis.existingClaim", value = "harbor-redis-pvc" },
    { name = "persistence.persistentVolumeClaim.trivy.existingClaim", value = "harbor-trivy-pvc" },
    # Resource limits
    { name = "resources.limits.cpu", value = "1000m" },
    { name = "resources.limits.memory", value = "1Gi" }
  ]
  depends_on_resource = [kubernetes_namespace.management, module.traefik_helm, module.cert_manager_helm, module.longhorn_helm, module.harbor_registry_pvc, module.harbor_database_pvc, module.harbor_jobservice_pvc, module.harbor_redis_pvc, module.harbor_trivy_pvc]
}
