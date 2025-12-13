# Deploying following Kubernetes Resources :
## Microservices
# - TBD
## App Services
# - TBD
## Supporting Services
# + PodMonitors for Istio Sidecar Monitoring
# + PeerAuthentication for Istio Sidcar Metrics Scraping

################################ Microservice Resources ################################


################################ App Service Resources ################################


################################ Supporting Service Resources ################################
# Deploying Istio Sidecar Monitoring for Prometheus
module "podmonitor_istio_sidecar" {
  source = "../cluster-templates/manifest"

  api_version = "monitoring.coreos.com/v1"
  kind        = "PodMonitor"
  namespace   = var.namespace
  metadata = {
    name      = "istio-sidecars-monitor"
    namespace = var.namespace
    labels = {
      "monitoring" = "dev-stack"
      "release"    = "kube-prometheus-stack"
    }
  }
  manifest_body       = var.istio_sidecar_monitoring_config
  depends_on_resource = [module.kube_prometheus_stack_helm, module.istiod_dev_helm]
}

# Deploying PeerAuthentication to allow Istio Sidecar Metrics Scraping
module "peerauthentication_istio_sidecar" {
  source = "../cluster-templates/manifest"

  api_version = "security.istio.io/v1beta1"
  kind        = "PeerAuthentication"
  namespace   = var.namespace
  metadata = {
    name      = "allow-istio-sidecar-metrics-scraping"
    namespace = var.namespace
  }
  manifest_body       = var.istio_sidecar_peerauthentication_config
  depends_on_resource = [module.istiod_dev_helm]
}
