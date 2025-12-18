################################ Compute Module Variables ##############################
variable "project_name" { type = string }
variable "subnet_id" { type = string }
variable "vpc_security_group_ids" { type = list(string) } # Bastion or VPN SG
variable "key_name" { type = string }
variable "name_prefix" { type = string } # e.g., "bastion" or "vpn"
variable "common_tags" { type = map(string) }
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}
