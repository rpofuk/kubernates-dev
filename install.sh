helm install prometheus prometheus-community/prometheus --set server.service.type=NodePort



kubectl apply https://devops-nirvana.s3.amazonaws.com/volume-autoscaler/volume-autoscaler-1.0.8.yaml
curl https://devops-nirvana.s3.amazonaws.com/volume-autoscaler/volume-autoscaler-1.0.8.yaml -o volume-autoscaler-1.0.8.yaml
cat volume-autoscaler-1.0.8.yaml | sed 's/"infrastructure"/"default"/g' > ./to_be_applied.yaml
# REPLACE prometheus-url
kubectl apply -f ./to_be_applied.yaml
