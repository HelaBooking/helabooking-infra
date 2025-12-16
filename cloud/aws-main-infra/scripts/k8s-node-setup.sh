#!/bin/bash

# --- CONFIGURATION INJECTED BY TERRAFORM ---
PROJECT_NAME="${project_name}"
NODE_ROLE="${node_role}"
REGION="${aws_region}"
BOOTSTRAP_SECRET_ID="${bootstrap_secret_id}"
K8S_VERSION="${k8s_version}"
# -------------------------------------------

# 1. Prevent interactive prompts
echo "\$nrconf{restart} = 'a';" > /etc/needrestart/needrestart.conf
export DEBIAN_FRONTEND=noninteractive

# 2. Install Dependencies (Including AWS CLI and JQ)
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg \
    net-tools btop software-properties-common jq unzip

# Install AWS CLI v2 (Ubuntu repos often have old versions)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install

# 3. Disable Swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 4. Networking Prerequisites
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# 5. Install Containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y containerd.io

containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd

# 6. Install Kubernetes Tools
curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 7. AUTO-JOIN LOGIC (The "Wait for Secret" Loop)
echo "------------------------------------------------"
echo "Starting Cluster Bootstrap Check..."
echo "Role: $NODE_ROLE"
echo "Secret ID: $BOOTSTRAP_SECRET_ID"
echo "------------------------------------------------"

while true; do
  # Fetch Secret JSON
  SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$BOOTSTRAP_SECRET_ID" --region "$REGION" --query SecretString --output text 2>/dev/null)

  if [[ -n "$SECRET_JSON" ]]; then
    # Check if we are Master or Worker and extract the specific command
    if [[ "$NODE_ROLE" == "master" ]]; then
       # Note: We check for 'master_join' key
       JOIN_CMD=$(echo "$SECRET_JSON" | jq -r '.master_join // empty')
    else
       # Note: We check for 'worker_join' key
       JOIN_CMD=$(echo "$SECRET_JSON" | jq -r '.worker_join // empty')
    fi

    # If we found a valid command (not null/empty), execute it
    if [[ -n "$JOIN_CMD" && "$JOIN_CMD" != "null" ]]; then
      echo "✅ Bootstrap command found! Joining cluster..."
      
      # Execute the join command
      eval "$JOIN_CMD"
      
      echo "🎉 Join Complete!"
      break
    else
      echo "⏳ Cluster secret exists, but '$NODE_ROLE' join command is missing. Waiting for Ansible..."
    fi
  else
    echo "❌ Secret not found or empty. Waiting for Ansible to create cluster..."
  fi

  sleep 30
done