# environments/dev/main.tf

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = var.env
      ManagedBy   = "terraform"
      Project     = "databricks"
    }
  }
}

# Workspace-level provider
# Points directly to YOUR existing workspace URL
# Authenticates via Service Principal (not personal token)
provider "databricks" {
  host          = var.workspace_url
  # These come from TF_VAR_* env vars in CI/CD
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

# Reference your existing S3 bucket (already created by Databricks)
# data source = READ existing resource, don't create it
data "aws_s3_bucket" "dbfs" {
  bucket = var.dbfs_bucket_name
}


# Reference your existing IAM cross-account role
data "aws_iam_role" "cross_account" {
  name = "databricks-rijaji8cryazpfxzgm67tw-cross-account-role"
}

# Reference your existing security group
data "aws_security_group" "databricks" {
  id = var.security_group
}

# Step 2: Create IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "GitHubActionsRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::021655150740:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Only YOUR repo can assume this role
          "token.actions.githubusercontent.com:sub" = "repo:YOUR_GITHUB_USERNAME/YOUR_REPO:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
