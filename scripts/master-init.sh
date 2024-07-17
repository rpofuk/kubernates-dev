#!/bin/bash

set -euo pipefail

vm_ip=$1 

echo "### Initializing cluster"
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --upload-certs --control-plane-endpoint=$vm_ip
echo "#######################"


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

curl -Lo tigera-operator.yaml https://docs.projectcalico.org/manifests/tigera-operator.yaml
curl -Lo custom-resources.yaml https://docs.projectcalico.org/manifests/custom-resources.yaml

kubectl create -f tigera-operator.yaml
kubectl create -f custom-resources.yaml

