# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
output "instance_id" {
  value = aws_instance.k8s_node.id
}

output "public_ip" {
  value = aws_instance.k8s_node.public_ip
}
