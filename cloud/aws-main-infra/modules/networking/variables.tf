################################ Networking Module Variables ##############################
variable "vpc_cidr" {
  type = string
}
variable "project_name" {
  type = string
}
variable "azs" {
  description = "List of Availability Zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"] # Using 2 AZs for redundancy
}
variable "common_tags" { type = map(string) }
