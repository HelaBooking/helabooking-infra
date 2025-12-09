
# -----------------------------------------------------------------------------
# SSH Key Generation
# -----------------------------------------------------------------------------
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/generated_key.pem"
  file_permission = "0400"
}

# -----------------------------------------------------------------------------
# Cluster Token
# -----------------------------------------------------------------------------
resource "random_password" "k3s_token" {
  length  = 32
  special = false
}

# -----------------------------------------------------------------------------
# AMI Lookup
# -----------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# -----------------------------------------------------------------------------
# Master Node
# -----------------------------------------------------------------------------
resource "aws_instance" "master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.master_instance_type
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.generated.key_name

  vpc_security_group_ids = [aws_security_group.k3s.id]

  tags = {
    Name = "${var.project_name}-master"
    Role = "master"
  }

  user_data = <<-EOF
              #!/bin/bash
              curl -sfL https://get.k3s.io | K3S_TOKEN=${random_password.k3s_token.result} sh -s - server --cluster-init
              EOF
}

# -----------------------------------------------------------------------------
# Worker Nodes
# -----------------------------------------------------------------------------
resource "aws_instance" "worker" {
  count         = var.worker_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.worker_instance_type
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.generated.key_name

  vpc_security_group_ids = [aws_security_group.k3s.id]

  # Ensure Master is created first so we have its Private IP
  depends_on = [aws_instance.master]

  tags = {
    Name = "${var.project_name}-worker-${count.index + 1}"
    Role = "worker"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Wait for master to be ready (simple sleep or check)
              sleep 30
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.master.private_ip}:6443 K3S_TOKEN=${random_password.k3s_token.result} sh -
              EOF
}
