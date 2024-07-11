#!/bin/bash 

set -euo pipefail 

# apt install cloud-utils
#
# network access sudo iptables -A FORWARD -p all -i br0 -j ACCEPT


export base_disk_file="ubuntu-vm-disk-base.qcow2"
export user_pwd="no-secret"

if [[ ! -f ubuntu-vm-disk-base.qcow2 ]]; then 
  echo "Base disk image does not exist, craeting new one"
  if [[ ! -f ubuntu.img ]]; then 
    echo "Image is not yet downloaded so downaloding fresh one"	  
    curl -Lo ubuntu.img 'https://cloud-images.ubuntu.com/noble/20240605.1/noble-server-cloudimg-amd64.img'
  else
    echo "Using exising image"
  fi

  echo "no-secret" > pass.txt 

  echo "Create base disk used for all VM's"
  qemu-img create -b ubuntu.img -F qcow2 -f qcow2 $base_disk_file 20G

fi



for name in "kubernetes-master"; do 
  ./create_vm.sh $name
  vm_ip=$(cat resp.txt)
  echo "Setting up $name on $vm_ip"
  master_ip=$vm_ip

  sshpass -f pass.txt scp -r scripts ubuntu@$vm_ip:/home/ubuntu/scripts

  sshpass -f pass.txt ssh ubuntu@$vm_ip '/home/ubuntu/scripts/setup-node.sh '"$vm_ip"' '"$name"' '
  sshpass -f pass.txt ssh ubuntu@$vm_ip '/home/ubuntu/scripts/master-init.sh '"$vm_ip"' '

  join_command="$(sshpass -f pass.txt ssh ubuntu@$vm_ip 'sudo kubeadm token create --print-join-command')"


  echo "Join command: $join_command"
done

echo "Creating nodes"

for name in kubernetes-node1 kubernetes-node2 kubernetes-node3; do 
  echo "Working on $name"
  ./create_vm.sh $name 
  vm_ip=$(cat resp.txt)

  sshpass -f pass.txt scp -r scripts ubuntu@$vm_ip:/home/ubuntu/scripts

  sshpass -f pass.txt ssh ubuntu@$vm_ip '/home/ubuntu/scripts/setup-node.sh '"$vm_ip"' '"$name"' '
  sshpass -f pass.txt ssh ubuntu@$vm_ip '/home/ubuntu/scripts/worker-init.sh '"$vm_ip"' "'"$join_command"'"'

done


