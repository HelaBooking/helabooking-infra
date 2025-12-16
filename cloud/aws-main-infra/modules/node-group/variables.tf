################################ Node Group Module Variables ##############################
variable "project_name" { type = string }
variable "role" { type = string } # "master" or "worker"
variable "min_size" { type = number }
variable "max_size" { type = number }
variable "desired_size" { type = number }
variable "instance_type" { type = string }
variable "subnets" { type = list(string) }
variable "security_groups" { type = list(string) }
variable "key_name" { type = string }
variable "iam_instance_profile_arn" { type = string }
variable "user_data_base64" { type = string }
variable "target_group_arns" {
  type    = list(string)
  default = [] # Only Masters need this
}
variable "common_tags" { type = map(string) }
variable "volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 50 # Default 50GB for K8s nodes
}
