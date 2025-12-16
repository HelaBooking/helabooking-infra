################################ AWS Security Groups ##############################
module "helabooking_security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.helabooking_network.vpc_id
  vpc_cidr     = var.vpc_cidr
  common_tags  = try(local.final_tags, var.common_tags)
  depends_on   = [module.helabooking_network]
}
