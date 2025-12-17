################################ Secrets Resources ##############################
# Secret for SSH Keys (Stores the Private Key securely)
resource "aws_secretsmanager_secret" "ssh_key" {
  name        = "${var.project_name}/ssh-keys/${var.key_name}"
  description = "SSH Private Key for ${var.project_name}'s nodes"
  tags        = var.common_tags

  recovery_window_in_days = 0
}

# Secret for K8s Bootstrap Token (Empty initially, populated by Ansible)
resource "aws_secretsmanager_secret" "k8s_bootstrap_join" {
  name        = "${var.project_name}/k8s-bootstrap-join"
  description = "Stores kubeadm join commands for Masters and Workers"
  tags        = var.common_tags

  recovery_window_in_days = 0
}

# Initial version for the Bootstrap secret (Empty JSON)
# Ensures the secret exists so nodes don't fail when trying to read it.
resource "aws_secretsmanager_secret_version" "k8s_bootstrap_join_init" {
  secret_id = aws_secretsmanager_secret.k8s_bootstrap_join.id
  secret_string = jsonencode({
    status = "waiting_for_ansible"
  })

  # Ignore changes because Ansible will update this secret later
  lifecycle {
    ignore_changes = [secret_string]
  }
}
