#!/bin/bash 

set -euo pipefail 

# apt install cloud-utils
#
# network access sudo iptables -A FORWARD -p all -i br0 -j ACCEPT


export work_dir=$PWD/target
mkdir -p $work_dir

echo "Work dir: $work_dir"
export base_disk_file="$work_dir/ubuntu-vm-disk-base.qcow2"
export user_pwd="no-secret"
export resp_file=$work_dir/resp.txt
export pass_file=$work_dir/pass.txt


echo "Checking if base is prepared"

if [[ ! -f $work_dir/ubuntu-vm-disk-base.qcow2 ]]; then 
  echo "Base disk image does not exist, craeting new one"
  if [[ ! -f $work_dir/ubuntu.img ]]; then 
    echo "Image is not yet downloaded so downaloding fresh one"	  
    curl -Lo $work_dir/ubuntu.img 'https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img'
  else
    echo "Using exising image"
  fi

  echo "no-secret" > $pass_file 

  echo "Create base disk used for all VM's"
  qemu-img create -b $work_dir/ubuntu.img -F qcow2 -f qcow2 $base_disk_file 30G
else 
  echo "Using old base volume"
fi


echo "Going to create me some nodes"

for name in "kubernetes-master"; do 
  ./scripts/create-vm.sh $name
  vm_ip=$(cat $resp_file)
  echo "Setting up $name on $vm_ip"
  master_ip=$vm_ip

  sshpass -f $pass_file scp -r scripts ubuntu@$vm_ip:/home/ubuntu/scripts

  sshpass -f $pass_file ssh ubuntu@$vm_ip '/home/ubuntu/scripts/setup-node.sh '"$vm_ip"' '"$name"' '
  sshpass -f $pass_file ssh ubuntu@$vm_ip '/home/ubuntu/scripts/master-init.sh '"$vm_ip"' '

  join_command="$(sshpass -f $pass_file ssh ubuntu@$vm_ip 'sudo kubeadm token create --print-join-command')"

  echo "Join command: $join_command"
done

echo "Creating nodes"

for name in kubernetes-node1 kubernetes-node2 kubernetes-node3; do 
  echo "Working on $name"
  ./scripts/create-vm.sh $name
  vm_ip=$(cat $resp_file)

  sshpass -f $pass_file scp -r scripts ubuntu@$vm_ip:/home/ubuntu/scripts

  sshpass -f $pass_file ssh ubuntu@$vm_ip '/home/ubuntu/scripts/setup-node.sh '"$vm_ip"' '"$name"' '
  sshpass -f $pass_file ssh ubuntu@$vm_ip '/home/ubuntu/scripts/worker-init.sh '"$vm_ip"' "'"$join_command"'"'

done


