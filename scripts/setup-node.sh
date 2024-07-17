#!/bin/bash

set -euo pipefail 

vm_ip=$1
name=$2


echo "### Setting hostname $name"
sudo hostname $name
echo "####################"


echo "### Instal standrad tools"

sudo apt install net-tools

echo "####################"

sudo echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

sudo apt-get install -y kubelet kubeadm kubectl

download_dir="$(mktemp -d)"

echo "Dowload dir: $download_dir"

containerd_verson=1.7.19
echo "### Installing containerd: $containerd_verson"
curl -L -o $download_dir/containerd.tar.gz "https://github.com/containerd/containerd/releases/download/v$containerd_verson/containerd-$containerd_verson-linux-amd64.tar.gz"
sudo tar -xvf $download_dir/containerd.tar.gz -C /usr/local
rm -rf containerd.tar.gz
echo "#####################"


runc_version="1.1.3"
echo "### Installing runc: $runc_version"
curl -L -o runc.amd64 "https://github.com/opencontainers/runc/releases/download/v$runc_version/runc.amd64"
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
echo "#####################"


echo "### Setup containerd"
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo curl -L "https://raw.githubusercontent.com/containerd/containerd/main/containerd.service" -o /etc/systemd/system/containerd.service

sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl status containerd    

echo "#####################"


echo "### Configure netfilter settings"

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
echo "###############################"

echo "Prepare kubernates"
sudo kubeadm config images pull
echo "#####################"

