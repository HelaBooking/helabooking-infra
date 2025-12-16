############################# Key Pair Outputs ##############################
output "ssh_key_name" {
  value = module.k8s_node_ssh_keys.key_pair_name
}

output "ssh_key_path" {
  value = module.k8s_node_ssh_keys.private_key_path
}
