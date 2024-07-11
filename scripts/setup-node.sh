#!/bin/bash

vm_ip=$1
name=$2


echo "### Setting hostname $name"
sudo hostname $name
echo "####################"


echo "### Instal standrad tools"

sudo apt install net-tools

echo "####################"

sudo echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >  /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

sudo apt-get install -y kubelet kubeadm kubectl

# Install docker
sudo apt-get install -y docker.io
sudo usermod -aG docker ${USER}

sudo tee /etc/docker/daemon.json<<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
###################################

sudo systemctl daemon-reload
sudo systemctl restart docker

# Configure netfilter settings

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
#yy##############################

sudo kubeadm config images pull


