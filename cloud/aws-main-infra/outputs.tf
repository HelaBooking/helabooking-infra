############################# Key Pair Outputs ##############################
################################################################################
# Connectivity Endpoints
################################################################################

output "bastion_public_ip" {
  description = "Public IP of the Bastion Host (Jump Box)"
  value       = module.helabooking_bastion_host.public_ip
}

output "vpn_public_ip" {
  description = "Public IP of the VPN Host (Wireguard)"
  value       = module.helabooking_vpn_host.public_ip
}

output "k8s_api_endpoint" {
  description = "Internal DNS of the Kubernetes API Server (NLB)"
  value       = module.helabooking_k8s_control_plane_lb.dns_name
}

################################################################################
# SSH & Key Information
################################################################################

output "ssh_private_key_path" {
  description = "Path to the generated private key file"
  value       = module.k8s_node_ssh_keys.private_key_path
}

output "ssh_command_example" {
  description = "Example command to SSH into Bastion"
  value       = "ssh -i ${module.k8s_node_ssh_keys.private_key_path} ubuntu@${module.helabooking_bastion_host.public_ip}"
}

output "ssh_proxy_command_example" {
  description = "Example command to SSH into a Private Node via Bastion"
  value       = "ssh -o ProxyCommand='ssh -W %h:%p -i ${module.k8s_node_ssh_keys.private_key_path} ubuntu@${module.helabooking_bastion_host.public_ip}' -i ${module.k8s_node_ssh_keys.private_key_path} ubuntu@<PRIVATE_NODE_IP>"
}

################################################################################
# Resource Identification (For Ansible/Automation)
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.helabooking_network.vpc_id
}

output "master_asg_name" {
  description = "Auto Scaling Group name for Master Nodes"
  value       = module.helabooking_k8s_control_plane_nodes.asg_name
}

output "worker_asg_name" {
  description = "Auto Scaling Group name for Worker Nodes"
  value       = module.helabooking_k8s_worker_nodes.asg_name
}
