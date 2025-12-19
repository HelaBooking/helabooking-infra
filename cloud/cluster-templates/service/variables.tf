# Variables used in templates

## For Namespaces
variable "namespace" {
  description = "Kubernetes namespace name"
  type        = string
}

## For Services
variable "service_name" {
  description = "Name of the Kubernetes service"
  type        = string
}

variable "app_selector" {
  description = "Label selector for the service to target the deployment"
  type        = string
}
variable "service_ports" {
  description = "List of service ports with names and target ports"
  type = list(object({
    name         = string
    value        = number
    target_value = number
    protocol     = string
  }))
  default = []
}
variable "service_type" {
  description = "Type of the Kubernetes service (e.g., ClusterIP, NodePort, LoadBalancer)"
  type        = string
  default     = "ClusterIP"
}
variable "depends_on_resource" {
  description = "Resource that this service depends on"
  type        = any
  default     = null
}
