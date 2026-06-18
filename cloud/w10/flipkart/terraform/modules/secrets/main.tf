# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
resource "aws_secretsmanager_secret" "db_password" {
  name                    = var.db_secret_name
  description             = "Flipkart DB password — consumed by External Secrets Operator"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    password = var.db_initial_password
  })

  lifecycle {
    # Rotation is the whole point of Lab 2.1: don't fight the AWS Console / CLI.
    ignore_changes = [secret_string]
  }
}

# Optional IRSA role for cross-account / EKS variants. For the Minikube node we
# rely on the EC2 instance profile in the compute module, but we still output
# this role ARN so the same Terraform works in EKS later.
data "aws_iam_policy_document" "eso_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eso" {
  name               = "${var.project}-eso"
  assume_role_policy = data.aws_iam_policy_document.eso_assume.json
}

data "aws_iam_policy_document" "eso_read" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [aws_secretsmanager_secret.db_password.arn]
  }
}

resource "aws_iam_role_policy" "eso_read" {
  name   = "${var.project}-eso-read"
  role   = aws_iam_role.eso.id
  policy = data.aws_iam_policy_document.eso_read.json
}
