############################## Global Variables ##############################
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}
variable "aws_availability_zones" {
  description = "List of AWS availability zones to use"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "helabooking-cloud" # Change this for new environments
}
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    CreatedBy   = "Terraform"
    Environment = "Prod" # Change this for new environments
    App         = "Helabooking-App"
    Project     = "helabooking-cloud" # Change this for new environments
  }
}
variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
  default     = "prod" # Change this for new environments
}

############################### Specific Variables ##############################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16" # Change this for new environments (use non overlapping CIDRs)
}
variable "secrets_bucket_name" {
  description = "Name of the S3 bucket for storing secrets"
  type        = string
  default     = "group9-secrets-bucket"
}
variable "k8s_version_to_use" {
  description = "Kubernetes version to use for the cluster"
  type        = string
  default     = "v1.34"
}
