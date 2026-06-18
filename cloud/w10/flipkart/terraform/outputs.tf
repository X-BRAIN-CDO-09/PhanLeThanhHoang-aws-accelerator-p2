# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
output "alb_dns_name" {
  description = "Public URL of the Flipkart ALB"
  value       = module.loadbalancing.alb_dns_name
}

output "ec2_public_ip" {
  description = "Public IP of the Minikube node (SSH from your IP only)"
  value       = module.compute.public_ip
}

output "db_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret consumed by External Secrets Operator"
  value       = module.secrets.db_secret_arn
}

output "db_secret_name" {
  description = "Name of the AWS Secrets Manager secret (use this in ExternalSecret)"
  value       = module.secrets.db_secret_name
}

output "irsa_role_arn" {
  description = "IAM role ARN that the ESO ServiceAccount should assume (IRSA-style)"
  value       = module.secrets.irsa_role_arn
}
