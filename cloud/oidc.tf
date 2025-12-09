# -----------------------------------------------------------------------------
# OIDC Provider (GitHub Actions)
# -----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub's generic thumbprint
}

# -----------------------------------------------------------------------------
# IAM Role for CI/CD
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "ci_cd" {
  name               = "HelabookingDeployRole"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

# -----------------------------------------------------------------------------
# Policy Attachment (Admin Access for simplicity)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ci_cd_admin" {
  role       = aws_iam_role.ci_cd.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "ci_cd_role_arn" {
  description = "ARN of the role to assume in CI/CD"
  value       = aws_iam_role.ci_cd.arn
}
