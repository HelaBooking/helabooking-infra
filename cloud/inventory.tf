resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    master_public_ip   = aws_instance.master.public_ip
    master_private_ip  = aws_instance.master.private_ip
    worker_public_ips  = aws_instance.worker[*].public_ip
    worker_private_ips = aws_instance.worker[*].private_ip
  })
  filename = "${path.module}/ansible/inventory.ini"
}
