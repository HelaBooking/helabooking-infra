################################ Key Pair Module Resources ##############################
# Generate Private Key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload Public Key to AWS
resource "aws_key_pair" "key_pair" {
  key_name   = "${var.project_name}-${var.key_pair_name}"
  public_key = tls_private_key.key.public_key_openssh

  tags       = merge(var.common_tags, { Name = "${var.project_name}-${var.key_pair_name}" })
  depends_on = [tls_private_key.key]
}

