#!/bin/bash

set -euo pipefail

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus

kubectl --namespace infrastructure apply https://devops-nirvana.s3.amazonaws.com/volume-autoscaler/volume-autoscaler-1.0.8.yaml
wget https://devops-nirvana.s3.amazonaws.com/volume-autoscaler/volume-autoscaler-1.0.8.yaml
curl https://devops-nirvana.s3.amazonaws.com/volume-autoscaler/volume-autoscaler-1.0.8.yaml -o volume-autoscaler-1.0.8.yaml

cat volume-autoscaler-1.0.8.yaml | sed 's/"infrastructure"/"default"/g' > ./to_be_applied.yaml
kubectl --namespace default apply -f ./to_be_applied.yaml

helm install prometheus prometheus-community/prometheus \
     --set server.ingress.enabled=true \
     --set server.ingress.hosts={prometheus.dev} \
     --set server.service.type=NodePort 
