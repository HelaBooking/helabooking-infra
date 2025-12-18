################################ AWS EC2 Resources ##############################
module "helabooking_bastion_host" {
  source                 = "./modules/compute"
  project_name           = var.project_name
  name_prefix            = "bastion"
  subnet_id              = module.helabooking_network.public_subnet_id
  vpc_security_group_ids = [module.helabooking_security.bastion_sg_id]
  key_name               = module.k8s_node_ssh_keys.key_pair_name
  common_tags            = try(local.final_tags, var.common_tags)
  depends_on             = [module.helabooking_network, module.helabooking_security, module.k8s_node_ssh_keys]
}

module "helabooking_vpn_host" {
  source                 = "./modules/compute"
  project_name           = var.project_name
  name_prefix            = "vpn"
  subnet_id              = module.helabooking_network.public_subnet_id
  vpc_security_group_ids = [module.helabooking_security.vpn_sg_id]
  key_name               = module.k8s_node_ssh_keys.key_pair_name
  common_tags            = try(local.final_tags, var.common_tags)
  depends_on             = [module.helabooking_network, module.helabooking_security, module.k8s_node_ssh_keys]
}
