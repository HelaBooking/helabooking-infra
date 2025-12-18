################################ AWS IAM Resources ##############################
module "helabooking_iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  common_tags  = try(local.final_tags, var.common_tags)
}
