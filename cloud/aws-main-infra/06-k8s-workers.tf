################################ AWS K8S Worker Plane ##############################
module "helabooking_k8s_worker_nodes" {
  source       = "./modules/node-group"
  project_name = var.project_name
  role         = "worker"

  # Scaling Config
  min_size      = 1
  max_size      = 4
  desired_size  = 2
  instance_type = "t3.large" # 2vCPU/8GB RAM
  volume_size   = 50         # 50GB root volume

  subnets         = module.helabooking_network.private_subnet_ids
  security_groups = [module.helabooking_security.common_sg_id]
  key_name        = module.k8s_node_ssh_keys.key_pair_name

  # Attach IAM (No Load Balancer for Workers in this ASG)
  iam_instance_profile_arn = module.helabooking_iam.worker_instance_profile_name

  # User Data
  user_data_base64 = base64encode(templatefile("${path.module}/scripts/k8s-node-setup.sh", {
    project_name        = var.project_name
    node_role           = "worker"
    aws_region          = var.aws_region
    bootstrap_secret_id = module.k8s_secrets.bootstrap_secret_id
  }))

  common_tags = try(local.final_tags, var.common_tags)
  depends_on  = [module.helabooking_network, module.helabooking_security, module.k8s_node_ssh_keys, module.helabooking_iam, module.helabooking_k8s_control_plane_nodes, module.k8s_secrets]
}
