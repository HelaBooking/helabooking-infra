################################ AWS Metadata for Ansible ##############################
resource "local_file" "metadata_json" {
  filename = "${path.module}/metadata.json"
  content = jsonencode({
    project_name = var.project_name
    vpc_id       = module.helabooking_network.vpc_id
    vpc_cidr     = var.vpc_cidr
    region       = var.aws_region

    # Connectivity
    bastion_public_ip = module.helabooking_bastion_host.public_ip
    vpn_public_ip     = module.helabooking_vpn_host.public_ip
    vpn_private_ip    = module.helabooking_vpn_host.private_ip

    # Kubernetes Info
    k8s_api_endpoint = module.helabooking_k8s_control_plane_lb.dns_name

    # Secrets Identifiers (For Ansible to fetch/update)
    bootstrap_secret_id = module.k8s_secrets.bootstrap_secret_id
    ssh_secret_id       = module.k8s_secrets.ssh_key_id

    # S3 Bucket Info
    s3_secrets_bucket = var.secrets_bucket_name
  })
}
