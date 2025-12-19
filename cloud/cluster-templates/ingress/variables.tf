variable "name" {
  description = "Ingress name"
  type        = string
}

variable "namespace" {
  description = "Ingress namespace"
  type        = string
}

variable "ingress_class_name" {
  description = "IngressClass name (e.g., alb-private, alb-public)"
  type        = string
}

variable "annotations" {
  description = "Additional annotations to apply to the ingress"
  type        = map(string)
  default     = {}
}

variable "rules" {
  description = "Ingress rules (host + path backends)"
  type = list(object({
    host = string
    paths = list(object({
      path         = string
      path_type    = optional(string)
      service_name = string
      service_port = number
    }))
  }))
}

variable "depends_on_resource" {
  description = "Resource that this ingress depends on"
  type        = any
  default     = null
}
