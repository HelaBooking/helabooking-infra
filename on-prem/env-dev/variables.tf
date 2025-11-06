# Variables for on-prem environment - development

# common variables
variable "namespace" {
  description = "Kubernetes namespace for the development environment"
  type        = string
  default     = "env-dev"
}

# Image versions
variable "couchdb_helm_version" {
  description = "Helm chart version for CouchDB"
  type        = string
  default     = "4.6.2"
}
variable "postgresql_image" {
  description = "Docker image for PostgreSQL"
  type        = string
  default     = "17-alpine"
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


# App specific configurations
# CouchDB configurations
variable "couchdb_uuid" {
  description = "UUID for CouchDB instance"
  type        = string
  default     = "ce56c886-17bc-43e9-9f79-b2a629ccbf19"
}
variable "couchdb_username" {
  description = "Admin username for CouchDB"
  type        = string
  default     = "testadmin"
}
variable "couchdb_password" {
  description = "Admin password for CouchDB"
  type        = string
  default     = "test@admin.123"
  sensitive   = true
}
# PostgreSQL configurations
variable "postgresql_username" {
  description = "Username for PostgreSQL"
  type        = string
  default     = "testadmin"
}
variable "postgresql_password" {
  description = "Password for PostgreSQL"
  type        = string
  default     = "test@admin.123"
  sensitive   = true
}
variable "postgresql_database" {
  description = "Database name for PostgreSQL"
  type        = string
  default     = "defaultdb"
}
