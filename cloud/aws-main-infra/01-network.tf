################################ AWS Networks ##############################
module "helabooking_network" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  common_tags  = try(local.final_tags, var.common_tags)
  azs          = var.aws_availability_zones
}
