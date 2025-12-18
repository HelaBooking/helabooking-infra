################################ Internal LB Module Outputs ##############################
output "dns_name" {
  value = aws_lb.kube_api_nlb.dns_name
}
output "target_group_arn" {
  value = aws_lb_target_group.kube_api_tg.arn
}
