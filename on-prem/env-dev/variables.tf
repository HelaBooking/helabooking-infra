################################ Common Variables ################################
variable "namespace" {
  description = "Kubernetes namespace for the development environment"
  type        = string
  default     = "env-dev"
}

# DNS Record configurations
variable "cf_default_root_domain" {
  description = "Root domain for the services"
  type        = string
  default     = "dev.ezbooking.lk"
}
variable "cf_default_record_value" {
  description = "Default Cloudflare DNS record pointing value"
  type        = string
  default     = "strangersmp.ddns.net"
}
variable "cluster_service_domain" {
  description = "Root domain for kubernetes cluster services"
  type        = string
  default     = "svc.cluster.local"
}

################################ Microservice Related Variables ################################
# TBD

################################ App Service Related Variables ################################
# Image/Helm Chart versions
variable "rabbitmq_helm_version" {
  description = "Version of RabbitMQ Helm chart"
  type        = string
  default     = "16.0.14"
}

# Specific configurations


################################ Supporting Service Related Variables ################################
# Enable or Disable Supporting Services
variable "enable_opensearch" {
  description = "Enable OpenSearch Cluster"
  type        = bool
  default     = true
}
variable "enable_opensearch_dashboard" {
  description = "Enable OpenSearch Dashboard"
  type        = bool
  default     = false
}
variable "enable_prometheus" {
  description = "Enable Prometheus & Alertmanager"
  type        = bool
  default     = true
}
variable "enable_grafana" {
  description = "Enable Grafana"
  type        = bool
  default     = false
}
variable "enable_pgadmin" {
  description = "Enable PGAdmin deployment"
  type        = bool
  default     = false
}
variable "enable_kiali_dashboard" {
  description = "Enable Kiali Dashboard deployment"
  type        = bool
  default     = true
}


# Image/Helm Chart versions
variable "pgadmin_image" {
  description = "Version of PGAdmin image"
  type        = string
  default     = "latest"
}
variable "opensearch_helm_version" {
  description = "Version of OpenSearch Helm chart"
  type        = string
  default     = "3.3.2"
}
variable "opensearch_dashboard_helm_version" {
  description = "Version of OpenSearch Dashboard Helm chart"
  type        = string
  default     = "3.3.0"
}
variable "kube_prometheus_stack_helm_version" {
  description = "Version of Grafana Helm chart"
  type        = string
  default     = "80.2.0"
}
variable "istiod_helm_version" {
  description = "Version of Istiod Helm chart"
  type        = string
  default     = "1.28.1"
}
variable "istiogateway_helm_version" {
  description = "Version of Istio Gateway Helm chart"
  type        = string
  default     = "1.28.1"
}
variable "kiali_helm_version" {
  description = "Version of Kiali Helm chart"
  type        = string
  default     = "2.19.0"
}

# Specific configurations
# OpenSearch
variable "opensearch_config_yaml" {
  description = "Custom OpenSearch configuration in YAML format"
  type        = string
  default     = <<EOT
discovery.type: single-node
network.host: 0.0.0.0
plugins.security.ssl.http.enabled: true
plugins.security.ssl.transport.enabled: true
plugins.alerting.enabled: true
EOT
}
# Grafana & Prometheus Operator
variable "prometheus_grafana_values" {
  description = "Custom values for Prometheus & Grafana Helm chart"
  type        = string
  default     = <<EOT
# --- Global Settings ---
fullnameOverride: "prometheus-dev"

# --- Cluster Monitoring (Enabled for Dev Stack) ---
nodeExporter:
  enabled: true
kubelet:
  enabled: true
  serviceMonitor:
    https: true
    insecureSkipVerify: true
kubeApiServer:
  enabled: true
kubeControllerManager:
  enabled: false # Disable for K3s
kubeScheduler:
  enabled: false # Disable for K3s
kubeStateMetrics:
  enabled: true
coreDns:
  enabled: false # Disable for K3s
kubeEtcd:
  enabled: false # Disable for K3s
kubeProxy:
  enabled: false # Disable for K3s

# --- Grafana Configuration ---
grafana:
  enabled: true
  defaultDashboardsEnabled: true
  
  # Enable Persistence (PVC)
  persistence:
    enabled: true
    type: statefulset
    storageClassName: longhorn
    accessModes: ["ReadWriteOnce"]
    size: 1Gi

  # FIX: Manually define the Data Source to ensure connection
  additionalDataSources:
    - name: Prometheus
      type: prometheus
      uid: prometheus
      access: proxy
      url: http://prometheus-dev-prometheus.env-dev.svc:9090
      isDefault: true
      jsonData:
        httpMethod: POST
        timeInterval: 30s

  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard
      searchNamespace: ["env-dev", "management"]
    datasources:
      enabled: true
      defaultDatasourceEnabled: false

# --- Prometheus Configuration ---
prometheus:
  prometheusSpec:
    # Only scrape in namespaces labeled "monitoring: dev-stack"
    serviceMonitorNamespaceSelector:
      matchLabels:
        monitoring: dev-stack
    podMonitorNamespaceSelector:
      matchLabels:
        monitoring: dev-stack
    ruleNamespaceSelector:
      matchLabels:
        monitoring: dev-stack
        
    # Setting these to '{}' (Empty) means "Select Everything in the namespace"
    serviceMonitorSelector: {}
    podMonitorSelector: {}
    ruleSelector: {}
    probeSelector: {}
    
    # Data Retention
    retention: 7d

# --- Alertmanager Configuration ---
alertmanager:
  enabled: true
EOT
}

# Istio 
variable "istio_namespace" {
  description = "Namespace where Istio is installed"
  type        = string
  default     = "istio-system"
}
variable "istio_sidecar_monitoring_config" {
  description = "Istio Sidecar Monitoring Configuration"
  type        = string
  default     = <<EOT
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: istio-sidecars-monitor
  namespace: env-dev
  labels:
    monitoring: dev-stack
    release: kube-prometheus-stack
spec:
  selector:
    matchExpressions:
    - key: istio-prometheus-ignore
      operator: DoesNotExist
  namespaceSelector:
    matchNames:
    - env-dev
    - istio-system
  podMetricsEndpoints:
  - path: /stats/prometheus
    interval: 15s
    relabelings:
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_container_name]
      regex: "istio-proxy"
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_annotationpresent_prometheus_io_scrape]
    - action: replace
      regex: (.*)
      replacement: $1
      sourceLabels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      targetLabel: __metrics_path__
    - action: replace
      regex: ([^:]+)(?::\d+)?;(\d+)
      replacement: $1:$2
      sourceLabels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
      targetLabel: __address__
EOT
}
