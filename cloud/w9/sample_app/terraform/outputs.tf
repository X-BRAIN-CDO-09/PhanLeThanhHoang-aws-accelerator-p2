output "alb_dns_name" {
  description = "Đường link để truy cập ứng dụng của bạn"
  value       = module.loadbalancing.alb_dns_name
}
