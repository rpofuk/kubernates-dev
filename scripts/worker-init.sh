#!/bin/bash

set -euo pipefail

echo "VM IP $1"
echo "JOIN CMD $2"

sudo systemctl enable kubelet

echo "### Joining cluster"
sudo $2
echo "###################"

