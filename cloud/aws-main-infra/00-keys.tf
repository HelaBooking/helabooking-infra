################################ AWS Key Pairs ##############################

module "k8s_node_ssh_keys" {
  source        = "./modules/key-pair"
  project_name  = var.project_name
  key_pair_name = "k8s-node-key"
  common_tags   = try(local.final_tags, var.common_tags)
}

output "ssh_key_name" {
  value = module.k8s_node_ssh_keys.key_pair_name
}

output "ssh_key_path" {
  value = module.k8s_node_ssh_keys.private_key_path
}
