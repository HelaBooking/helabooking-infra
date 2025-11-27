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

# Specific configurations
