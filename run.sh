#!/bin/bash

set -euo pipefail

export work_dir=$PWD/target
export pass_file=$work_dir/pass.txt


cmd=$1
file=$2

vm_ip="$(virsh domifaddr kubernetes-master | grep vnet | awk '{printf $4}' |  sed 's/\/.*//g')"
sshpass -f $pass_file scp $PWD/$2 ubuntu@$vm_ip:/home/ubuntu/$1
sshpass -f $pass_file ssh ubuntu@$vm_ip kubectl $cmd -f /home/ubuntu/$1

