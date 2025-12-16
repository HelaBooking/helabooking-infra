################################ IAM Module Outputs ##############################
output "master_instance_profile_name" { value = aws_iam_instance_profile.master.name }
output "worker_instance_profile_name" { value = aws_iam_instance_profile.worker.name }
