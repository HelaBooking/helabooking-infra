################################ Compute Module Resources ##############################
# Ubuntu 24.04 AMI Lookup
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_name

  vpc_security_group_ids = var.vpc_security_group_ids
  # Ensure Source/Dest check is disabled for VPN routing
  source_dest_check = var.name_prefix == "vpn" ? false : true

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
    encrypted             = true
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-${var.name_prefix}-root-vol"
    })
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.name_prefix}"
  })
}

resource "aws_eip" "ec2_eip" {
  instance = aws_instance.ec2.id
  domain   = "vpc"
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.name_prefix}-eip"
  })
}
