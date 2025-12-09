output "master_public_ip" {
  description = "Public IP of K3s Master"
  value       = aws_instance.master.public_ip
}

output "master_private_ip" {
  description = "Private IP of K3s Master (Internal)"
  value       = aws_instance.master.private_ip
}

output "master_instance_id" {
  description = "AWS Instance ID of K3s Master"
  value       = aws_instance.master.id
}

output "worker_public_ips" {
  description = "Public IPs of Worker Nodes"
  value       = aws_instance.worker[*].public_ip
}

output "worker_private_ips" {
  description = "Private IPs of Worker Nodes (Internal)"
  value       = aws_instance.worker[*].private_ip
}

output "worker_instance_ids" {
  description = "AWS Instance IDs of Worker Nodes"
  value       = aws_instance.worker[*].id
}

output "ssh_connect_command" {
  description = "Command to SSH into Master"
  value       = "ssh -i generated_key.pem ubuntu@${aws_instance.master.public_ip}"
}

output "private_key_path" {
  value       = "${path.module}/generated_key.pem"
  description = "Path to the private key"
}

output "k3s_token" {
  description = "Cluster Token (sensitive)"
  value       = random_password.k3s_token.result
  sensitive   = true
}
