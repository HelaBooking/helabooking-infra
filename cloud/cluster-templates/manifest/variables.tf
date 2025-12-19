# Variables used in templates

## For Namespaces (legacy; not used by this module)
variable "namespace" {
  description = "Kubernetes namespace name (unused; kept for backward compatibility)"
  type        = string
  default     = null
}

## For Manifests
variable "api_version" {
  description = "API version of the Kubernetes resource"
  type        = string
}
variable "kind" {
  description = "Kind of the Kubernetes resource"
  type        = string
}
variable "metadata" {
  description = "Metadata for the Kubernetes resource"
  type = object({
    name        = string
    namespace   = optional(string)
    labels      = optional(map(string))
    annotations = optional(map(string))
  })
}
variable "manifest_body" {
  description = "YAML string representing the body of the Kubernetes resource (spec, data, etc.)"
  type        = string
}
variable "depends_on_resource" {
  description = "Resource that this service depends on"
  type        = any
  default     = null
}
