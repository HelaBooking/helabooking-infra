################################ AWS K8S Master Plane ##############################
# Internal NLB for API Server
module "helabooking_k8s_control_plane_lb" {
  source       = "./modules/internal-lb"
  project_name = var.project_name
  vpc_id       = module.helabooking_network.vpc_id
  subnets      = module.helabooking_network.private_subnet_ids
  common_tags  = try(local.final_tags, var.common_tags)
  depends_on   = [module.helabooking_network, module.helabooking_security, module.k8s_secrets]
}

# Master Nodes ASG
module "helabooking_k8s_control_plane_nodes" {
  source       = "./modules/node-group"
  project_name = var.project_name
  role         = "master"

  # Scaling Config
  min_size      = 1
  max_size      = 1
  desired_size  = 1
  instance_type = "t3.large" # 2vCPU/8GB RAM
  volume_size   = 50         # 50GB root volume

  subnets         = module.helabooking_network.private_subnet_ids
  security_groups = [module.helabooking_security.common_sg_id]
  key_name        = module.k8s_node_ssh_keys.key_pair_name

  # Attach IAM & Load Balancer
  iam_instance_profile_arn = module.helabooking_iam.master_instance_profile_name
  target_group_arns        = [module.helabooking_k8s_control_plane_lb.target_group_arn]

  # User Data
  user_data_base64 = base64encode(templatefile("${path.module}/scripts/k8s-node-setup.sh", {
    project_name        = var.project_name
    node_role           = "master"
    aws_region          = var.aws_region
    bootstrap_secret_id = module.k8s_secrets.bootstrap_secret_id
    k8s_version         = var.k8s_version_to_use
  }))

  common_tags = try(local.final_tags, var.common_tags)
  depends_on  = [module.helabooking_network, module.helabooking_security, module.k8s_node_ssh_keys, module.helabooking_iam, module.k8s_secrets]
}
