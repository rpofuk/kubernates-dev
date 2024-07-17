#!/bin/bash 

set -euo pipefail 

export work_dir=$PWD/target
export pass_file=$work_dir/pass.txt


ips="$(virsh list | grep "running" | awk '{print $2}' | xargs -I {} virsh domifaddr {} | grep vnet | awk '{printf $4"\n"}' | sed 's/\/.*//g' )"
echo $ips
for vm_ip in $ips; do 
   echo "Cleaning $vm_ip"
   if [[ "$1" == "skip" ]]; then
     sshpass -f $pass_file ssh ubuntu@$vm_ip sudo ls -lah /opt/
   else 
     sshpass -f $pass_file ssh ubuntu@$vm_ip sudo rm -rf /opt/test.img
     sshpass -f $pass_file ssh ubuntu@$vm_ip df -h
   fi

done	


