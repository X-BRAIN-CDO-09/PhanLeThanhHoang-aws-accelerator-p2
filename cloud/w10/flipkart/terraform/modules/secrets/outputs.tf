# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}

output "db_secret_name" {
  value = aws_secretsmanager_secret.db_password.name
}

output "irsa_role_arn" {
  value = aws_iam_role.eso.arn
}
