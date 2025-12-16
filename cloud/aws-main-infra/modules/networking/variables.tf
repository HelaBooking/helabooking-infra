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
  default     = ["apse1-az1", "apse1-az2"] # Using 2 AZs for redundancy
}
