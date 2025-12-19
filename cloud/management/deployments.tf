# Deploying following cluster resources:
# + AWS EBS StorageClass (requires AWS EBS CSI driver installed in cluster)
# + Cert-Manager
# + NGINX Proxy Manager

# Deploying Project Common Resources:
# + Jenkins + Trivy (Vulnerability Scanning)
# + Harbor
# + ArgoCD
# + Fluent Bit
# + Istio Base Components


################################ Cluster Resources ################################

# Deploying Traefik Ingress Controller (Internal only) using helm-chart template
module "traefik_helm" {
  source = "../cluster-templates/helm-chart"

  chart_name       = "traefik"
  chart_repository = "https://traefik.github.io/charts"
  chart            = "traefik"
  namespace        = kubernetes_namespace.management.metadata[0].name
  chart_version    = var.traefik_version
  set_values = [
    { name = "dashboard.enabled", value = "true" },
    { name = "ports.websecure.tls.enabled", value = "true" },
    { name = "ports.websecure.port", value = "443" },
    { name = "ports.web.port", value = "80" },
    { name = "service.type", value = "ClusterIP" },
    { name = "providers.kubernetesIngress.publishedService.enabled", value = "true" },
    { name = "providers.kubernetesIngress.publishedService.pathOverride", value = "management/traefik" },
    { name = "replicas", value = "1" },
    { name = "resources.requests.cpu", value = "50m" },
    { name = "resources.requests.memory", value = "50Mi" }
  ]
  depends_on_resource = kubernetes_namespace.management
}

# AWS EBS CSI Driver (required for dynamic provisioning via ebs.csi.aws.com)
module "aws_ebs_csi_driver_helm" {
  source = "../cluster-templates/helm-chart"

  chart_name       = "aws-ebs-csi-driver"
  chart_repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart            = "aws-ebs-csi-driver"
  namespace        = "kube-system"
  chart_version    = var.aws_ebs_csi_driver_version

  # Keep chart minimal; relies on node IAM role/instance profile by default.
  set_values = [
    { name = "controller.serviceAccount.create", value = "true" },
    { name = "node.serviceAccount.create", value = "true" },
  ]
}

# AWS EBS CSI StorageClass (gp3)
resource "kubernetes_storage_class" "ebs_gp3" {
  metadata {
    name = "ebs-gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }

  depends_on = [module.aws_ebs_csi_driver_helm]
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
    { name = "resources.limits.cpu", value = "500m" },
    { name = "resources.limits.memory", value = "256Mi" },
    { name = "resources.requests.cpu", value = "100m" },
    { name = "resources.requests.memory", value = "100Mi" }
  ]
  depends_on_resource = [kubernetes_namespace.cert_manager, module.traefik_helm]
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
  cpu_request    = "100m"
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
  # Custom Values
  custom_values = var.jenkins_agent_config

  set_values = [
    { name = "controller.admin.password", value = var.jenkins_admin_password },
    { name = "controller.serviceType", value = "ClusterIP" },
    { name = "controller.resources.limits.cpu", value = "1000m" },
    { name = "controller.resources.limits.memory", value = "2Gi" },
    { name = "persistence.existingClaim", value = "jenkins-pvc" },
    { name = "controller.jenkinsUrl", value = "https://jenkins.${var.cf_default_root_domain}/" },
    # Agent configs - Defined in the custom_values variable
    # Plugins
    {
      name = "controller.additionalPlugins",
      value_list = [
        "github-branch-source:1917.v9ee8a_39b_3d0d",
        "ansicolor:1.0.6",
        "generic-webhook-trigger:2.4.1",
        "git-parameter:460.v71e7583a_c099"
      ]
    },
    # Config as Code (JCasC) scripts
    { name = "controller.JCasC.configScripts.git-creds", value = var.jenkins_git_credentials },
    { name = "controller.JCasC.configScripts.aws-creds", value = var.jenkins_aws_credentials },
    { name = "controller.JCasC.configScripts.harbor-creds", value = var.harbor_credentials }
  ]
  depends_on_resource = [kubernetes_namespace.management, module.traefik_helm, module.jenkins_pvc]
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
    # PVCs used in harbor
    { name = "persistence.persistentVolumeClaim.registry.existingClaim", value = "harbor-registry-pvc" },
    { name = "persistence.persistentVolumeClaim.database.existingClaim", value = "harbor-database-pvc" },
    { name = "persistence.persistentVolumeClaim.jobservice.jobLog.existingClaim", value = "harbor-jobservice-pvc" },
    { name = "persistence.persistentVolumeClaim.redis.existingClaim", value = "harbor-redis-pvc" },
    { name = "persistence.persistentVolumeClaim.trivy.existingClaim", value = "harbor-trivy-pvc" },
    # Resource limits
    { name = "resources.limits.cpu", value = "1000m" },
    { name = "resources.limits.memory", value = "2Gi" }
  ]
  depends_on_resource = [kubernetes_namespace.management, module.traefik_helm, module.cert_manager_helm, module.harbor_registry_pvc, module.harbor_database_pvc, module.harbor_jobservice_pvc, module.harbor_redis_pvc, module.harbor_trivy_pvc]
}

# Deploying ArgoCD
module "argocd_helm" {
  source = "../cluster-templates/helm-chart"

  chart_name       = "argo-cd"
  chart_repository = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace.management.metadata[0].name
  chart_version    = var.argocd_version
  set_values = [
    { name = "global.domain", value = "argocd.${var.cf_default_root_domain}" },
    { name = "server.ingress.enabled", value = "false" },
    { name = "configs.secret.argocdServerAdminPassword", value = var.argocd_admin_password_hash },
    { name = "server.resources.requests.cpu", value = "400m" },
    { name = "server.resources.requests.memory", value = "512Mi" },
    # Forces ArgoCD to mark Ingress as "Healthy" even without an IP address
    {
      name  = "configs.cm.resource\\.customizations\\.health\\.networking\\.k8s\\.io_Ingress"
      value = "hs = {}\nhs.status = \"Healthy\"\nhs.message = \"Ingress is Healthy (IP check bypassed for ClusterIP)\"\nreturn hs"
    }
  ]
  depends_on_resource = [kubernetes_namespace.management, module.traefik_helm, module.cert_manager_helm]
}

# Deploying Fluent Bit
module "fluentbit_helm" {
  source = "../cluster-templates/helm-chart"

  chart_name       = "fluent-bit"
  chart_repository = "https://fluent.github.io/helm-charts"
  chart            = "fluent-bit"
  namespace        = kubernetes_namespace.management.metadata[0].name
  chart_version    = var.fluentbit_version

  set_values = [
    { name = "resources.requests.cpu", value = "100m" },
    { name = "resources.requests.memory", value = "100Mi" },
    { name = "resources.limits.cpu", value = "400m" },
    { name = "resources.limits.memory", value = "512Mi" },
    { name = "config.service", value = var.fluentbit_config_service },
    { name = "config.inputs", value = var.fluentbit_config_inputs },
    { name = "config.filters", value = var.fluentbit_config_filters },
    { name = "config.outputs", value = var.fluentbit_config_outputs }
  ]
  depends_on_resource = [kubernetes_namespace.management, module.traefik_helm]
}

# Deploying Istio Base Chart
module "istio_base_helm" {
  source           = "../cluster-templates/helm-chart"
  chart_name       = "istio-base"
  chart_repository = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = kubernetes_namespace.istio_system.metadata[0].name
  chart_version    = var.istio_base_helm_version

  depends_on = [kubernetes_namespace.istio_system]
}
