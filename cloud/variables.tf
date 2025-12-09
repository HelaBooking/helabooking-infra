variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "helabooking-staging"
}

variable "master_instance_type" {
  description = "Instance type for K3s Master"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for K3s Worker"
  type        = string
  default     = "t3.large"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for instance access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "github_repo" {
  description = "GitHub repository (username/repo) for OIDC trust"
  type        = string
  default     = "HelaBooking/helabooking-infra"
}
