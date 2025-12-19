# Variables used in templates

## For Namespaces
variable "namespace" {
  description = "Kubernetes namespace name"
  type        = string
}

## For Helm Charts
variable "chart_name" {
  description = "Name of the Helm release"
  type        = string
}
variable "chart_repository" {
  description = "Helm chart repository URL"
  type        = string
}
variable "chart" {
  description = "Name of the Helm chart"
  type        = string
}
variable "chart_version" {
  description = "Version of the Helm chart"
  type        = string
}
variable "set_values" {
  description = "List of values to set in the Helm chart"
  type = list(object({
    name = string
    # value is string or list of strings
    value      = optional(string)
    value_list = optional(list(string))
  }))
  default = []
}
variable "custom_values" {
  description = "Raw YAML string for complex configurations (lists of objects, etc.)"
  type        = string
  default     = ""
}
variable "depends_on_resource" {
  description = "Resource that this service depends on"
  type        = any
  default     = null
}
