################################ Key Pair Module Variables ##############################
variable "project_name" {
  description = "Project name to be used for tagging and naming"
  type        = string
}
variable "env" {
  description = "Environment (e.g., dev, prod) for naming"
  type        = string
}
variable "key_pair_name" {
  description = "Name of the key pair"
  type        = string
}
