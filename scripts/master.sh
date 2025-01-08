#!/bin/bash
#
# Setup for Control Plane (Master) servers

set -euxo pipefail

# Configuration
PUBLIC_IP_ACCESS="false"
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"

# Validate PUBLIC_IP_ACCESS
if [[ "$PUBLIC_IP_ACCESS" != "true" && "$PUBLIC_IP_ACCESS" != "false" ]]; then
    echo "Error: Invalid value for PUBLIC_IP_ACCESS: $PUBLIC_IP_ACCESS"
    exit 1
fi

# Disable swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Pull required images
sudo kubeadm config images pull

# Initialize kubeadm
if [[ "$PUBLIC_IP_ACCESS" == "false" ]]; then
    MASTER_PRIVATE_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
    sudo kubeadm init --apiserver-advertise-address="$MASTER_PRIVATE_IP" --apiserver-cert-extra-sans="$MASTER_PRIVATE_IP" --pod-network-cidr="$POD_CIDR" --node-name "$NODENAME" --ignore-preflight-errors Swap
else
    MASTER_PUBLIC_IP=$(curl -s ifconfig.me)
    sudo kubeadm init --control-plane-endpoint="$MASTER_PUBLIC_IP" --apiserver-cert-extra-sans="$MASTER_PUBLIC_IP" --pod-network-cidr="$POD_CIDR" --node-name "$NODENAME" --ignore-preflight-errors Swap
fi

# Capture the join command
JOIN_COMMAND=$(kubeadm token create --print-join-command)
echo "$JOIN_COMMAND" > join-command.txt
echo "Use the following command to join worker nodes to the cluster:"
cat join-command.txt

# Configure kubeconfig
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

# Wait for the control plane to be ready
kubectl wait --for=condition=Ready node/"$NODENAME" --timeout=300s

# Install Calico Network Plugin
CALICO_VERSION="v3.26.0"
kubectl apply -f https://docs.projectcalico.org/$CALICO_VERSION/manifests/calico.yaml
