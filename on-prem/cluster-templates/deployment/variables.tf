# Variables used in templates


## For Namespaces
variable "namespace" {
  description = "Kubernetes namespace name"
  type        = string
}


## For Deployments
variable "app_name" {
  description = "Name of the application"
  type        = string
}
variable "selector_label" {
  description = "Label selector for the deployment"
  type        = string
}
variable "app_image" {
  description = "Docker image of the application"
  type        = string
}
variable "replicas" {
  description = "Number of replicas for the deployment"
  type        = number
  default     = 1
}
variable "container_ports" {
  description = "List of container ports"
  type = list(object({
    name  = string
    value = number
  }))
  default = []
}
variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "500m"
}
variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "256Mi"
}
variable "cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "175m"
}
variable "memory_request" {
  description = "Memory request for the container"
  type        = string
  default     = "128Mi"
}
variable "volume_configs" {
  description = "Volume configurations for the deployment"
  type = list(object({
    name       = string
    mount_path = string
    pvc_name   = optional(string) # Optional
    config_map = optional(string) # Optional
    config_map_items = optional(list(object({
      key  = string
      path = string
    })), [])
  }))
  default = []
}

variable "image_pull_secret" {
  description = "Image pull secret for private registries"
  type        = string
  default     = ""
}
variable "env_variable" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
# variable "probe_container_port" {
#   description = "Container port for health checks"
#   type        = number
# }
# variable "liveness_path" {
#   description = "HTTP path for liveness probe"
#   type        = string
# }
# variable "readiness_path" {
#   description = "HTTP path for readiness probe"
#   type        = string
# }
variable "depends_on_resource" {
  description = "Resource that this service depends on"
  type        = any
  default     = null
}
