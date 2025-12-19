############################## Common Variables ##############################
variable "namespace" {
  description = "Kubernetes namespace for management services"
  type        = string
  default     = "management"
}

variable "aws_region" {
  description = "AWS region for Route53 and other AWS resources"
  type        = string
  default     = "ap-southeast-1"
}

# DNS / Domain configurations
variable "cf_default_root_domain" {
  description = "Root domain for the management services (used as Route53 hosted zone name)"
  type        = string
  default     = "hela.ezbooking.lk"
}

variable "create_route53_hosted_zone" {
  description = "Whether to create a Route53 hosted zone for cf_default_root_domain"
  type        = bool
  default     = true
}

variable "enable_cloudflare_delegation" {
  description = "If true, creates NS records in Cloudflare to delegate to the Route53 hosted zone"
  type        = bool
  default     = false
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token (required if enable_cloudflare_delegation=true)"
  type        = string
  default     = null
  sensitive   = true
}

variable "cloudflare_parent_zone_id" {
  description = "Cloudflare Zone ID for the parent zone (e.g., ezbooking.lk) where the NS delegation record will be created"
  type        = string
  default     = null
}

variable "cloudflare_delegation_record_name" {
  description = "The NS record name in Cloudflare for delegation (typically the subdomain label, e.g., 'management')"
  type        = string
  default     = "hela"
}
variable "cluster_service_domain" {
  description = "Root domain for kubernetes cluster services"
  type        = string
  default     = "svc.cluster.local"

}

############################## Cluster Management Variables ##############################
# Image/Helm Chart versions
variable "cert_manager_version" {
  description = "Version of Cert-Manager Helm chart"
  type        = string
  default     = "1.18.2"
}

############################## Project Variables ##############################
# Image/Helm Chart versions
variable "jenkins_version" {
  description = "Version of Jenkins Helm chart"
  type        = string
  default     = "5.8.114"
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
variable "fluentbit_version" {
  description = "Version of Fluent Bit Helm chart"
  type        = string
  default     = "0.54.0"
}
variable "istio_base_helm_version" {
  description = "Version of Istio Helm chart"
  type        = string
  default     = "1.28.1"
}

# Specific configurations
# Jenkins
variable "jenkins_agent_config" {
  description = "YAML configuration for Jenkins BuildKit container"
  type        = string
  default     = <<EOT
agent:
  podName: "jenkins-agent"
  # Max Number of agents
  containerCap: 1
  
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
      cpu: "100m"
      memory: "200Mi"

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
          cpu: "100m"
          memory: "256Mi"
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

# Fluent Bit
variable "fluentbit_config_service" {
  description = "Services YAML configuration for Fluent Bit"
  type        = string
  default     = <<EOT
[SERVICE]
    Flush        1
    Daemon       Off
    Log_Level    info
    Parsers_File parsers.conf
    HTTP_Server  On
    HTTP_Port    2020
    Health_Check On
EOT
}
variable "fluentbit_config_inputs" {
  description = "Inputs YAML configuration for Fluent Bit"
  type        = string
  default     = <<EOT
[INPUT]
    Name             tail
    Path             /var/log/containers/*.log
    Parser           docker
    Tag              kube.*
    Refresh_Interval 5
    Mem_Buf_Limit    5MB
    Skip_Long_Lines  On
EOT
}
variable "fluentbit_config_filters" {
  description = "Filters YAML configuration for Fluent Bit"
  type        = string
  default     = <<EOT
[FILTER]
    Name                kubernetes
    Match               kube.*
    Kube_URL            https://kubernetes.default.svc:443
    Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
    Kube_Tag_Prefix     kube.var.log.containers.
    Merge_Log           On
    Keep_Log            Off

# Route 'management' namespace to the management tag
[FILTER]
    Name                rewrite_tag
    Match               kube.*
    Rule                $kubernetes['namespace_name'] ^(management)$ opensearch.management false
    
# Route 'env-dev' namespace to the DEV tag
[FILTER]
    Name                rewrite_tag
    Match               kube.*
    Rule                $kubernetes['namespace_name'] ^(env-dev)$ opensearch.dev false
EOT
}
