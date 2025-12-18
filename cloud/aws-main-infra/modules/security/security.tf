################################ Security Module Resources ##############################
# Bastion Host SG (Public Access)
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Allow SSH access to Bastion Host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from World"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "SSH from VPN Node"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.vpn.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-bastion-sg" })
}

# VPN Host SG (Wireguard)
resource "aws_security_group" "vpn" {
  name        = "${var.project_name}-vpn-sg"
  description = "Security group for Wireguard VPN"
  vpc_id      = var.vpc_id

  # Wireguard UDP Port
  ingress {
    description = "Wireguard UDP"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH Access (Restrict to Bastion)
  ingress {
    description     = "SSH Access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  ingress {
    description     = "SSH from VPN Node"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.vpn.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-vpn-sg" })
}

# Kubernetes Cluster Common SG (Cilium & Inter-node communication)
# This SG will be attached to BOTH Masters and Workers
resource "aws_security_group" "k8s_common" {
  name        = "${var.project_name}-k8s-common-sg"
  description = "Common SG for all K8s nodes (Masters & Workers)"
  vpc_id      = var.vpc_id

  # ALLOW ALL INTERNAL TRAFFIC (Required for Cilium/Istio Mesh)
  ingress {
    description = "Allow all internal traffic between nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Allow SSH from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  ingress {
    description     = "SSH from VPN Node"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.vpn.id]
  }

  # Allow API Server access from Bastion (for kubectl on bastion)
  ingress {
    description     = "API Server from Bastion"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Allow API Server access from VPN (if routing through VPN)
  ingress {
    description     = "API Server from VPN"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.vpn.id]
  }

  # Allow traffic from the VPC CIDR (Useful for Internal NLB health checks)
  ingress {
    description = "Allow VPC Internal Traffic (NLB Health Checks)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name                                        = "${var.project_name}-k8s-common-sg"
    "kubernetes.io/cluster/${var.project_name}" = "owned"
  })
}
