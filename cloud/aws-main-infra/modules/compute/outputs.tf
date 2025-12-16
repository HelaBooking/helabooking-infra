################################ Compute Module Outputs ##############################
output "public_ip" {
  value = aws_eip.ec2_eip.public_ip
}
output "private_ip" {
  value = aws_instance.ec2.private_ip
}
