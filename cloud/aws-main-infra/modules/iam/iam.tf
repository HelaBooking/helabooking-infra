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

# C. Secrets Manager Policy
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-secrets-access-policy"
  description = "Allow nodes to read project secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        # Restrict access ONLY to secrets starting with the project name
        Resource = "arn:aws:secretsmanager:*:*:${var.project_name}/*"
      }
    ]
  })
}

# D. Node AWS Integration Policy for Master Nodes
resource "aws_iam_role_policy" "node_aws_integration_master" {
  name = "${var.project_name}-node-aws-integration-k8s-master-policy"
  role = aws_iam_role.master.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
# E. Node AWS Integration Policy for Worker Nodes
resource "aws_iam_role_policy" "node_aws_integration_worker" {
  name = "${var.project_name}-node-aws-integration-k8s-worker-policy"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
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

# Attach Secrets Manager Access Policy to BOTH Roles
resource "aws_iam_role_policy_attachment" "master_secrets_attach" {
  role       = aws_iam_role.master.name
  policy_arn = aws_iam_policy.secrets_access.arn
}
# Attach to Worker Role
resource "aws_iam_role_policy_attachment" "worker_secrets_attach" {
  role       = aws_iam_role.worker.name
  policy_arn = aws_iam_policy.secrets_access.arn
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
