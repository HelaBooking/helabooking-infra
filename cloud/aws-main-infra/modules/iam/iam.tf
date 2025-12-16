################################ IAM Module Resources ##############################
# --- IAM Policies ---

# Policy for AWS Load Balancer Controller & EBS CSI Driver.
# Use AWS Managed Policies where possible to keep it simple.

# --- IAM Roles ---

# A. Master Node Role
resource "aws_iam_role" "master" {
  name = "${var.project_name}-k8s-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = var.common_tags
}

# B. Worker Node Role
resource "aws_iam_role" "worker" {
  name = "${var.project_name}-k8s-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = var.common_tags
}

# --- Policy Attachments ---

# Attach EBS CSI Driver Policy (Managed by AWS) to BOTH
resource "aws_iam_role_policy_attachment" "master_ebs" {
  role       = aws_iam_role.master.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
resource "aws_iam_role_policy_attachment" "worker_ebs" {
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Attach SSM Core (Allows you to shell into nodes via AWS Console if SSH breaks)
resource "aws_iam_role_policy_attachment" "master_ssm" {
  role       = aws_iam_role.master.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "worker_ssm" {
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CUSTOM POLICY: AWS Load Balancer Controller (Simplified)
# Attach a "PowerUser" or similar for now
# For this setup, Custom policy allowing ELB management is created.
resource "aws_iam_role_policy" "alb_controller" {
  name = "${var.project_name}-alb-policy"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:Describe*",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# ---  Instance Profiles ---
# Attach to the EC2 instances
resource "aws_iam_instance_profile" "master" {
  name = "${var.project_name}-master-iam-profile"
  role = aws_iam_role.master.name
}
resource "aws_iam_instance_profile" "worker" {
  name = "${var.project_name}-worker-iam-profile"
  role = aws_iam_role.worker.name
}
