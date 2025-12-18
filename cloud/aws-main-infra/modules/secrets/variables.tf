################################ Secrets Module Variables ##############################
variable "project_name" { type = string }
variable "common_tags" { type = map(string) }
variable "key_name" {
  type    = string
  default = "common-ssh-key"
}
