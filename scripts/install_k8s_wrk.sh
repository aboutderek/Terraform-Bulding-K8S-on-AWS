#!/bin/bash

######### ** FOR WORKER NODE ** #########

hostname k8s-wrk-${worker_number}
echo "k8s-wrk-${worker_number}" > /etc/hostname

export AWS_DEFAULT_REGION=${region}

echo "[TASK 1] Disable and turn off SWAP"
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

echo "[TASK 2] Stop and Disable firewall"
sudo systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 3] Install AWS CLI"
apt update
apt install awscli -y

echo "[TASK 4] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "[TASK 5] Add Kernel settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null 2>&1

echo "[TASK 6] Install containerd runtime"
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt -qq update >/dev/null 2>&1
apt install -qq -y containerd.io >/dev/null 2>&1
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd >/dev/null 2>&1

echo "[TASK 7] Add apt repo for kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - >/dev/null 2>&1
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/dev/null 2>&1

echo "[TASK 8] Install Kubernetes components (kubeadm, kubelet and kubectl)"
apt install -qq -y kubeadm=1.28.0-00 kubelet=1.28.0-00 kubectl=1.28.0-00 >/dev/null 2>&1


echo "[TASK 9] Join master node"
sleep 1m
aws s3 cp s3://${s3buckit_name}/join_command.sh /tmp/.
chmod +x /tmp/join_command.sh
bash /tmp/join_command.sh