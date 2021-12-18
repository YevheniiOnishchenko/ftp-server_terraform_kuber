#!/bin/bash

set -e

terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve

echo "$(terraform -chdir=terraform output -raw kube_config)" > ./terraform/connect.yml

export KUBECONFIG=./terraform/connect.yml

# Generate the ssh key pair
ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key <<<n >/dev/null 2>&1
ssh-keygen -t ed25519 -f ssh_host_ed25519_key <<<n >/dev/null 2>&1
kubectl create secret generic ssh-privatekey --from-file ssh_host_rsa_key --from-file ssh_host_ed25519_key

kubectl apply -f ./kubernetes

echo -e '\n IP of website: \t'
external_ip=""
while [ -z $external_ip ]; do
    sleep 10
    external_ip=$(kubectl get svc web --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
done
echo $external_ip

echo -e '\n IP of a host: \t'
external_ip=""
while [ -z $external_ip ]; do
    sleep 10
    external_ip=$(kubectl get svc ftp-service --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
done
echo $external_ip
