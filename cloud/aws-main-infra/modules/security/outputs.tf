################################ Security Module Outputs ##############################
output "bastion_sg_id" { value = aws_security_group.bastion.id }
output "vpn_sg_id" { value = aws_security_group.vpn.id }
output "common_sg_id" { value = aws_security_group.k8s_common.id }
