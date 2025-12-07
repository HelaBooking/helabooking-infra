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
