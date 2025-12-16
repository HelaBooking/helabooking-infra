# Terraform configuration for AWS provisioning
terraform {
  # Backend configuration
  backend "s3" {
    bucket       = "group9-terraform-state-bucket"
    key          = "cloud/aws-main-infra-terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# Locals
# Static time resource (Prevents the date from changing on every apply)
resource "time_static" "creation" {}

# Local variable that merges common_tags with the Date
locals {
  final_tags = merge(var.common_tags, {
    Date = formatdate("YYYY-MM-DD", time_static.creation.rfc3339)
  })
}

# Configure the Providers
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.final_tags
  }
}
