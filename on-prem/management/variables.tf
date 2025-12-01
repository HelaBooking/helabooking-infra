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
  default     = "5.8.110"
}
variable "harbor_version" {
  description = "Version of Harbor Helm chart"
  type        = string
  default     = "1.18.0"
}
variable "argocd_version" {
  description = "Version of ArgoCD Helm chart"
  type        = string
  default     = "9.1.4"
}

# Specific configurations
# Jenkins
variable "jenkins_agent_node_selector_hostname" {
  description = "Node selector hostname for Jenkins agents"
  type        = string
  default     = "galaxy-node"
}
variable "jenkins_controller_node_selector_hostname" {
  description = "Node selector hostname for Jenkins controller"
  type        = string
  default     = "pico-node"
}
variable "jenkins_agent_config" {
  description = "YAML configuration for Jenkins BuildKit container"
  type        = string
  default     = <<EOT
agent:
  podName: "jenkins-agent"
  # Node Selection 
  nodeSelector:
    kubernetes.io/hostname: "galaxy-node"
  
  # Agent Lifecycle
  idleMinutes: 10080
  
  # Permissions & Networking
  hostNetworking: false
  privileged: true
  runAsUser: 0
  runAsGroup: 0
  
  # Main JNLP Container Resources
  resources:
    limits:
      cpu: "1000m"
      memory: "1Gi"
    requests:
      cpu: "512m"
      memory: "512Mi"

  # Sidecar (BuildKit)
  additionalContainers:
    - sideContainerName: buildkit
      image:
        repository: moby/buildkit
        tag: latest
      args: ""
      privileged: true
      securityContext:
        privileged: true
        runAsUser: 0
        runAsGroup: 0
      resources:
        limits:
          cpu: "1000m"
          memory: "1Gi"
        requests:
          cpu: "500m"
          memory: "512Mi"
      volumeMounts:
        - name: workspace-volume
          mountPath: /workspace
        - name: buildkit-socket
          mountPath: /run/buildkit

  # Volumes
  yamlTemplate: |
      spec:
        volumes:
          - name: buildkit-socket
            emptyDir: {}
EOT
}
