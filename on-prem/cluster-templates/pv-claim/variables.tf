# Variables used in templates

## PVC variables
variable "pvc_name" {
  description = "Name of the Persistent Volume Claim"
  type        = string
}
variable "namespace" {
  description = "Kubernetes namespace name"
  type        = string
}
variable "app_selector" {
  description = "App label selector for the PVC"
  type        = string
}
variable "access_modes" {
  description = "Access modes for the PVC"
  type        = list(string)
  default     = ["ReadWriteOnce"]
}
variable "storage_request" {
  description = "Storage request for the PVC (e.g., 10Gi)"
  type        = string
}
variable "storage_class_name" {
  description = "Storage class name for the PVC"
  type        = string
  default     = "longhorn-sc"
}
variable "depends_on_resource" {
  description = "Resource that this PVC depends on"
  type        = any
  default     = null
}
