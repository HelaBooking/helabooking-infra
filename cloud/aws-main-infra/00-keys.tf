################################ AWS Key Pairs ##############################
# Create SSH key pairs for nodes
module "k8s_node_ssh_keys" {
  source        = "./modules/key-pair"
  project_name  = var.project_name
  key_pair_name = "k8s-node-key"
  common_tags   = try(local.final_tags, var.common_tags)
}

# Upload Private Key to Secrets Manager
resource "aws_secretsmanager_secret_version" "ssh_key_value_update" {
  secret_id     = module.k8s_secrets.ssh_key_id
  secret_string = module.k8s_node_ssh_keys.private_key_pem
}

# Outputs
output "ssh_key_name" {
  value = module.k8s_node_ssh_keys.key_pair_name
}

output "ssh_key_path" {
  value = module.k8s_node_ssh_keys.private_key_path
}
