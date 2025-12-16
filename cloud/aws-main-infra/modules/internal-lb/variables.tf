################################ Internal LB Module Variables ##############################
variable "project_name" { type = string }
variable "subnets" { type = list(string) } # Private Subnets
variable "vpc_id" { type = string }
variable "common_tags" { type = map(string) }
