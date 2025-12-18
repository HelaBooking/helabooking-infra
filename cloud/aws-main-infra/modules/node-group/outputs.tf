################################ Node Group Module Outputs ##############################
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.k8s_node_asg.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.k8s_node_lt.id
}
