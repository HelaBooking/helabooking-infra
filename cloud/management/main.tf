# Terraform configuration for cloud (AWS) Kubernetes cluster management
terraform {
  backend "s3" {
    bucket       = "group9-terraform-state-bucket"
    key          = "cloud/management-terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Configure the providers
provider "kubernetes" {
  config_path = "../cluster-configs/kube-config.yaml"
}
provider "helm" {
  kubernetes {
    config_path = "../cluster-configs/kube-config.yaml"
  }
}
