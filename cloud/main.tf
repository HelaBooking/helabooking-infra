# Terraform configuration for Cloud Kubernetes cluster management
# See individual files for resources:
# - vpc.tf: Networking
# - security_groups.tf: Firewalls
# - compute.tf: EC2 Instances & User Data
# - versions.tf: Providers
# - variables.tf: Input variables
# - outputs.tf: Output values

# -----------------------------------------------------------------------------
# Ansible Inventory Generation
# -----------------------------------------------------------------------------
resource "local_file" "ansible_inventory" {
  content = <<-EOF
    [master]
    ${aws_instance.master.public_ip} ansible_user=ubuntu

    [worker]
    %{for ip in aws_instance.worker[*].public_ip~}
    ${ip} ansible_user=ubuntu
    %{endfor~}

    [k3s_cluster:children]
    master
    worker
  EOF
  filename = "${path.module}/ansible/inventory.ini"
}
