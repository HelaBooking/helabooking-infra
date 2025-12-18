################################ Secrets Module Outputs ##############################
output "ssh_key_arn" {
  value = aws_secretsmanager_secret.ssh_key.arn
}

output "ssh_key_id" {
  value = aws_secretsmanager_secret.ssh_key.id
}

output "bootstrap_secret_arn" {
  value = aws_secretsmanager_secret.k8s_bootstrap_join.arn
}

output "bootstrap_secret_id" {
  value = aws_secretsmanager_secret.k8s_bootstrap_join.id
}
