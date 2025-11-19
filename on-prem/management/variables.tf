############################## Common Variables ##############################
variable "namespace" {
  description = "Kubernetes namespace for management services"
  type        = string
  default     = "management"
}

# DNS Record configurations
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

############################## Cluster Management Variables ##############################
# Image/Helm Chart versions
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



############################## Project Variables ##############################
# Image/Helm Chart versions
variable "jenkins_version" {
  description = "Version of Jenkins Helm chart"
  type        = string
  default     = "5.8.108"
}
variable "harbor_version" {
  description = "Version of Harbor Helm chart"
  type        = string
  default     = "1.18.0"
}

# Specific configurations
# Jenkins
variable "jenkins_agent_node_selector_hostname" {
  description = "Node selector hostname for Jenkins agents"
  type        = string
  default     = "galaxy-node"
}
variable "jenkins_agent_config" {
  description = "YAML configuration for Jenkins BuildKit container"
  type        = string
  default     = <<EOT
agent:
  additionalContainers:
    - sideContainerName: buildkit
      image:
        repository: moby/buildkit
        tag: latest
      args: "--oci-worker-no-process-sandbox"
      securityContext:
        runAsUser: 0
        runAsGroup: 0
        privileged: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /workspace
        - name: workspace-volume
          mountPath: /root/.docker
          subPath: .docker
        - name: buildkit-socket
          mountPath: /run/buildkit
  volumes:
    - name: workspace-volume
      emptyDir: {}
    - name: buildkit-socket
      emptyDir: {}
EOT
}
