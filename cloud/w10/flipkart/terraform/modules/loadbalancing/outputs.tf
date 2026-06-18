# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "tg_arn" {
  value = aws_lb_target_group.tg.arn
}
