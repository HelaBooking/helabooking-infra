[master]
${master_public_ip} ansible_host=${master_public_ip} ansible_user=ubuntu private_ip=${master_private_ip}

[worker]
%{ for index, ip in worker_public_ips ~}
${ip} ansible_host=${ip} ansible_user=ubuntu private_ip=${worker_private_ips[index]}
%{ endfor ~}

[k3s_cluster:children]
master
worker
