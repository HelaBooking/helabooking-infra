############################## Global Variables ##############################
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "helabooking-cloud" # Change this for DR environments
}
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    CreatedBy   = "Terraform"
    Environment = "Prod" # Change this for DR environments
    Project     = "Helabooking-App"
  }
}
variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
  default     = "prod"
}

############################### Specific Variables ##############################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "secrets_bucket_name" {
  description = "Name of the S3 bucket for storing secrets"
  type        = string
  default     = "group9-secrets-bucket"
}
