terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }

  # ---------------------------------------------------------------------------
  # BACKEND CONFIGURATION (Uncomment AFTER first apply)
  # ---------------------------------------------------------------------------
  # backend "s3" {
  #   bucket         = "helabooking-terraform-state-xxxx" # Replace xxxx with your random suffix
  #   key            = "staging/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "helabooking-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}
