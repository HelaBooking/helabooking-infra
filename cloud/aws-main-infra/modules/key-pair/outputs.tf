################################ Key Pair Module Outputs ##############################
output "key_pair_name" {
  description = "The AWS Key Pair name"
  value       = aws_key_pair.key_pair.key_name
}

output "private_key_pem" {
  description = "The private key data (Sensitive)"
  value       = tls_private_key.key.private_key_pem
  sensitive   = true
}

output "private_key_path" {
  description = "Path to the local private key file"
  value       = "keys/${aws_key_pair.key_pair.key_name}.pem"
}
