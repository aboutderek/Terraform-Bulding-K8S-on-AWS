#!/bin/bash

hostname k8s-msr-1
echo "k8s-msr-1" > /etc/hostname

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


echo "[TASK 9] Kubernetes cluster init"
export ipaddr=`ip address|grep eth0|grep inet|awk -F ' ' '{print $2}' |awk -F '/' '{print $1}'`
export pubip=`dig +short myip.opendns.com @resolver1.opendns.com`

kubeadm init --apiserver-advertise-address=$ipaddr --pod-network-cidr=172.16.0.0/16 --apiserver-cert-extra-sans=$pubip > /tmp/restult.out
cat /tmp/restult.out

echo "[TASK 10] to get join commnd"

tail -2 /tmp/restult.out > /tmp/join_command.sh;
aws s3 cp /tmp/join_command.sh s3://${s3buckit_name};
#this adds .kube/config for root account, run same for ubuntu user, if you need it
sudo mkdir -p /root/.kube;
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config;
sudo cp -i /etc/kubernetes/admin.conf /tmp/admin.conf;
sudo chmod 755 /tmp/admin.conf

echo "[TASK 11] Add kube config to ubuntu user"
sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#to copy kube config file to s3
# aws s3 cp /etc/kubernetes/admin.conf s3://${s3buckit_name}

echo "[TASK 12] Install Pod Network"
sudo curl -o /root/kube-flannel.yml https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
sleep 5
sudo sed -i "s/10.244.0.0/172.16.0.0/g" /root/kube-flannel.yml
sudo sed -i "/mgr/a\        - --iface=eth0" /root/kube-flannel.yml
sudo kubectl --kubeconfig /root/.kube/config apply -f /root/kube-flannel.yml
sudo systemctl restart kubelet

echo "[TASK 13] Apply kubectl Cheat Sheet Autocomplete"
source <(kubectl completion bash) # set up autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> /home/ubuntu/.bashrc # add autocomplete permanently to your bash shell.
echo "source <(kubectl completion bash)" >> /root/.bashrc # add autocomplete permanently to your bash shell.
alias k=kubectl
complete -o default -F __start_kubectl k
echo "alias k=kubectl" >> /home/ubuntu/.bashrc
echo "alias k=kubectl" >> /root/.bashrc
echo "complete -o default -F __start_kubectl k" >> /home/ubuntu/.bashrc
echo "complete -o default -F __start_kubectl k" >> /root/.bashrc