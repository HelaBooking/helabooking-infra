################################ Node Group Module Resources ##############################
# AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Launch Template
resource "aws_launch_template" "k8s_node_lt" {
  name_prefix   = "${var.project_name}-${var.role}-k8s-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.security_groups
  }

  block_device_mappings {
    device_name = "/dev/sda1" # Ubuntu root device
    ebs {
      volume_size           = var.volume_size
      volume_type           = "gp3"
      iops                  = 3000 # Free baseline
      throughput            = 125  # Free baseline
      delete_on_termination = true
      encrypted             = true # Best practice
    }
  }

  iam_instance_profile {
    name = var.iam_instance_profile_arn
  }

  user_data = var.user_data_base64

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name                                        = "${var.project_name}-${var.role}-k8s-node"
      Role                                        = var.role
      "kubernetes.io/cluster/${var.project_name}" = "owned"
    })
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      image_id
    ]
  }

}

# Auto Scaling Group
resource "aws_autoscaling_group" "k8s_node_asg" {
  name                = "${var.project_name}-${var.role}-k8s-asg"
  vpc_zone_identifier = var.subnets
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.desired_size

  target_group_arns = var.target_group_arns # Masters will attach to NLB here

  launch_template {
    id      = aws_launch_template.k8s_node_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.role}-k8s-node"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # For Cluster Autoscaler discovery (if you use it later)
  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.project_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
