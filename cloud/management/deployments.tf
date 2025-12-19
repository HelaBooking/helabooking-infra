# Deploying following cluster resources:
# + AWS EBS StorageClass (requires AWS EBS CSI driver installed in cluster)
# + AWS ALB IngressClasses (requires AWS Load Balancer Controller installed in cluster)
# + Cert-Manager

# Deploying Project Common Resources:
# + Jenkins + Trivy (Vulnerability Scanning)
# + Harbor
# + ArgoCD
# + Fluent Bit
# + Istio Base Components

# - Hashicorp Vault
# - WSO2 Identity Server (Optional)
# - Ansible (Outside of cluster)


################################ Cluster Resources ################################

# AWS EBS CSI StorageClass (gp3)
resource "kubernetes_storage_class" "ebs_gp3" {
  metadata {
    name = "ebs-gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }
}

# AWS ALB IngressClasses
module "alb_ingress_class_public" {
  source      = "../cluster-templates/manifest"
  api_version = "networking.k8s.io/v1"
  kind        = "IngressClass"

  metadata = {
    name = "alb-public"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "true"
    }
  }

  manifest_body = <<EOT
spec:
  controller: ingress.k8s.aws/alb
EOT
}

module "alb_ingress_class_private" {
  source      = "../cluster-templates/manifest"
  api_version = "networking.k8s.io/v1"
  kind        = "IngressClass"

  metadata = {
    name = "alb-private"
  }

  manifest_body = <<EOT
spec:
  controller: ingress.k8s.aws/alb
EOT
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
    { name = "resources.requests.cpu", value = "50m" },
    { name = "resources.requests.memory", value = "100Mi" }
  ]
  depends_on_resource = [kubernetes_namespace.cert_manager]
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
    { name = "controller.nodeSelector.kubernetes\\.io/hostname", value = var.jenkins_controller_node_selector_hostname },
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
  depends_on_resource = [kubernetes_namespace.management, module.jenkins_pvc]
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
  depends_on_resource = [kubernetes_namespace.management, module.cert_manager_helm, module.harbor_registry_pvc, module.harbor_database_pvc, module.harbor_jobservice_pvc, module.harbor_redis_pvc, module.harbor_trivy_pvc]
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
    { name = "server.resources.requests.cpu", value = "100m" },
    { name = "server.resources.requests.memory", value = "256Mi" },
    # Forces ArgoCD to mark Ingress as "Healthy" even without an IP address
    {
      name  = "configs.cm.resource\\.customizations\\.health\\.networking\\.k8s\\.io_Ingress"
      value = "hs = {}\nhs.status = \"Healthy\"\nhs.message = \"Ingress is Healthy (IP check bypassed for ClusterIP)\"\nreturn hs"
    }
  ]
  depends_on_resource = [kubernetes_namespace.management, module.cert_manager_helm]
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
    { name = "resources.requests.cpu", value = "50m" },
    { name = "resources.requests.memory", value = "64Mi" },
    { name = "resources.limits.cpu", value = "200m" },
    { name = "resources.limits.memory", value = "128Mi" },
    { name = "config.service", value = var.fluentbit_config_service },
    { name = "config.inputs", value = var.fluentbit_config_inputs },
    { name = "config.filters", value = var.fluentbit_config_filters },
    { name = "config.outputs", value = var.fluentbit_config_outputs }
  ]
  depends_on_resource = [kubernetes_namespace.management]
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
