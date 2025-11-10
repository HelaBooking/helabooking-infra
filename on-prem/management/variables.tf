############################## Cluster Management Variables ##############################
# Variables for on-prem cluster management
# Helm chart versions
variable "traefik_version" {
  description = "Version of Traefik Helm chart"
  type        = string
  default     = "37.1.1"
}
variable "cert_manager_version" {
  description = "Version of Cert-Manager Helm chart"
  type        = string
  default     = "1.18.2"
}
variable "rancher_version" {
  description = "Version of Rancher Helm chart"
  type        = string
  default     = "2.12.1"
}
variable "longhorn_version" {
  description = "Version of Longhorn Helm chart"
  type        = string
  default     = "1.9.1"
}
variable "nginx_proxy_manager_version" {
  description = "Version of NGINX Proxy Manager Helm chart"
  type        = string
  default     = "2.12.6"

}

# Specific configurations
variable "rancher_hostname" {
  description = "Hostname for Rancher server"
  type        = string
  default     = "rancher.management.ezbooking.lk"
}
variable "namespace" {
  description = "Kubernetes namespace for management services"
  type        = string
  default     = "management"
}
variable "cf_default_root_domain" {
  description = "Root domain for the management services"
  type        = string
  default     = "management.ezbooking.lk"
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


############################## Project Variables ##############################
# Helm chart versions for project services
variable "jenkins_version" {
  description = "Version of Jenkins Helm chart"
  type        = string
  default     = "5.8.107"
}

# Specific configurations for project services
