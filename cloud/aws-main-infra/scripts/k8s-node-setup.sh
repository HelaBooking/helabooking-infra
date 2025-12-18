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

# --- AWS INTEGRATION: SOURCE/DEST & HOSTNAME ---
# Use $$ for Bash variables so Terraform ignores them
TOKEN=$$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$$(curl -s -H "X-aws-ec2-metadata-token: $$TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
REGION=$$(curl -s -H "X-aws-ec2-metadata-token: $$TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

# 1. Disable Source/Dest Check (Required for Calico)
aws ec2 modify-instance-attribute --instance-id "$$INSTANCE_ID" --no-source-dest-check --region "$$REGION"

# 2. Fetch Name Tag and Set Hostname
TAG_NAME=$$(aws ec2 describe-tags \
  --filters "Name=resource-id,Values=$$INSTANCE_ID" "Name=key,Values=Name" \
  --region "$$REGION" --query 'Tags[0].Value' --output text)

# Make TAG unique by appending Last two parts of local IPv4
LOCAL_IPV4=$$(curl -s -H "X-aws-ec2-metadata-token: $$TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
IP_SUFFIX=$$(echo "$$LOCAL_IPV4" | awk -F. '{print $$(NF-1)"-"$$NF}')
TAG_NAME="$${TAG_NAME}-$${IP_SUFFIX}"

if [ ! -z "$$TAG_NAME" ] && [ "$$TAG_NAME" != "None" ]; then
  # Set the OS hostname
  hostnamectl set-hostname "$$TAG_NAME"
  
  # Update /etc/hosts to prevent sudo/init delays
  echo "127.0.0.1 $$TAG_NAME" >> /etc/hosts
  echo "Hostname updated to $$TAG_NAME"
fi
# -----------------------------------------------

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
apt-get install -y containerd

containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd

# 6. Install Kubernetes Tools
curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 7. PERSISTENT AUTO-JOIN & MAINTENANCE LOGIC
echo "------------------------------------------------"
echo "Initializing Background Cluster Maintainer..."
echo "------------------------------------------------"

# Create a dedicated maintenance script
cat <<EOF > /usr/local/bin/k8s-maintainer.sh
#!/bin/bash

check_if_joined() {
    # Check if the join config exists and kubelet is active
    if [[ -f "/etc/kubernetes/kubelet.conf" ]] && systemctl is-active --quiet kubelet; then
        return 0 # Joined
    else
        return 1 # Not joined
    fi
}

while true; do
    if check_if_joined; then
        echo "\$(date): Node is already healthy and joined to a cluster."
    else
        echo "\$(date): Node is NOT in a cluster. Checking for bootstrap secret..."
        
        # Fetch Secret JSON
        SECRET_JSON=\$(aws secretsmanager get-secret-value --secret-id "$BOOTSTRAP_SECRET_ID" --region "$REGION" --query SecretString --output text 2>/dev/null)

        if [[ -n "\$SECRET_JSON" ]]; then
            # Extract role-specific command
            if [[ "$NODE_ROLE" == "master" ]]; then
                JOIN_CMD=\$(echo "\$SECRET_JSON" | jq -r '.master_join // empty')
            else
                JOIN_CMD=\$(echo "\$SECRET_JSON" | jq -r '.worker_join // empty')
            fi

            if [[ -n "\$JOIN_CMD" && "\$JOIN_CMD" != "null" ]]; then
                echo "\$(date): ✅ Valid join command found! Preparing node..."
                
                # 1. Clean up any stale state from previous clusters
                kubeadm reset -f
                rm -rf /etc/cni/net.d
                iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
                
                # 2. Execute the join command
                echo "\$(date): Executing: \$JOIN_CMD"
                eval "\$JOIN_CMD"
                
                if [ \$? -eq 0 ]; then
                    echo "\$(date): 🎉 Successfully joined the cluster!"
                    systemctl restart kubelet
                else
                    echo "\$(date): ❌ Join failed. Will retry in next cycle."
                fi
            else
                echo "\$(date): ⏳ Secret exists but '$NODE_ROLE' command is empty. Ansible is likely still working..."
            fi
        else
            echo "\$(date): ❌ Secret not found in AWS Secrets Manager."
        fi
    fi

    # Check every 30 seconds
    sleep 30
done
EOF

# Make the script executable
chmod +x /usr/local/bin/k8s-maintainer.sh

# Run the maintainer in the background (survives session exit)
nohup /usr/local/bin/k8s-maintainer.sh > /var/log/k8s-maintainer.log 2>&1 &

echo "🎉 Maintainer started in background. Monitor progress with: tail -f /var/log/k8s-maintainer.log"