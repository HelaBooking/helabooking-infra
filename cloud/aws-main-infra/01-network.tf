################################ AWS Networks ##############################
module "helabooking_network" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr

  azs = ["apse1-az1", "apse1-az2"]
}
