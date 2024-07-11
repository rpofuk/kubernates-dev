#!/bin/bash 


set -euo pipefail 

name=$1

disk_path="$PWD/ubuntu-vm-disk-$name.qcow2"
cloud_init_path="$PWD/user-data-$name.qcow2"


virsh shutdown "$name" || echo "Nothing to shutdown"
sleep 5
virsh undefine "$name" || echo "Nothing to undefine"
sleep 5

echo "Creating disk for $name"
qemu-img create -f qcow2 \
   -o backing_file=$base_disk_file -o backing_fmt=qcow2 \
   $disk_path

qemu-img create -f qcow2 \
   -o backing_file=$base_disk_file -o backing_fmt=qcow2 \
   $disk_path

cat >user-data.txt <<EOF
#cloud-config
password: $user_pwd
chpasswd: { expire: False }
ssh_pwauth: True
EOF

echo "Cloud init data"
cat user-data.txt
echo "Creating disk to be mounted for user-data"
cloud-localds user-data-$name.img user-data.txt

echo "Creating VM $name"
virt-install \
  --virt-type kvm \
  --name $name \
  --ram=4096 \
  --boot hd\
  --vcpus 2 \
  --disk path=$disk_path,device=disk \
  --disk path=user-data-$name.img,format=raw \
  --network=default \
  --os-variant ubuntu24.04 \
  --graphics none \
  --noautoconsole \
  --import

echo "Getting ip"
virsh domifaddr $name
while [[ ! $(virsh domifaddr $name | grep vnet | awk '{print $4}' | cut -d/ -f 1) ]]; do
  echo "Waiting for IP" 
  sleep 3
done

vm_ip="$(virsh domifaddr $name | grep vnet | awk '{print $4}' | cut -d/ -f 1)"
echo "Connecting to $vm_ip" 

ssh-keygen -R $vm_ip

while [[ $(sshpass -f pass.txt ssh -o StrictHostKeyChecking=no ubuntu@$vm_ip echo "OK") != "OK" ]]; do
  echo "Retrying ..." 
  sleep 3
done

ssh-keyscan -H $vm_ip >> ~/.ssh/known_hosts

echo "$vm_ip" > resp.txt 

