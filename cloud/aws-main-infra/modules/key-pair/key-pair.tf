################################ Key Pair Module Resources ##############################
# Generate Private Key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload Public Key to AWS
resource "aws_key_pair" "key_pair" {
  key_name   = "${var.project_name}-${var.env}-${var.key_pair_name}"
  public_key = tls_private_key.key.public_key_openssh

  tags = {
    Name = "${var.project_name}-${var.env}-${var.key_pair_name}"
  }
}

# Save Private Key Locally
resource "local_file" "private_key" {
  content = tls_private_key.key.private_key_pem
  # Saving it to the root keys/ folder (jumping up two levels from the module)
  filename        = "${path.root}/keys/${var.project_name}-${var.env}-${var.key_pair_name}.pem"
  file_permission = "0600"
}
