################################ AWS Key Pairs ##############################

module "k8s_node_ssh_keys" {
  source        = "./modules/key-pair"
  project_name  = var.project_name
  env           = var.environment
  key_pair_name = "k8s-node-key"
}
