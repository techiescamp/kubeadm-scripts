#!/bin/bash

# Simple Calico CNI Installation Script with CIDR Auto-Configuration

set -e

echo "Installing Calico CNI..."

# Install Tigera Operator and CRDs
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/operator-crds.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/tigera-operator.yaml

# Download custom resources
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/custom-resources.yaml

# Get cluster CIDR from kube-controller-manager
CLUSTER_CIDR=$(kubectl -n kube-system get pod -l component=kube-controller-manager -o yaml | grep -i cluster-cidr | awk '{print $2}' | sed 's/--cluster-cidr=//')

if [ -z "$CLUSTER_CIDR" ]; then
    echo "Warning: Could not detect cluster CIDR, using default 10.244.0.0/16"
    CLUSTER_CIDR="10.244.0.0/16"
fi

echo "Using cluster CIDR: $CLUSTER_CIDR"

# Update CIDR in custom-resources.yaml
sed -i "s|cidr: 192.168.0.0/16|cidr: $CLUSTER_CIDR|g" custom-resources.yaml

# Apply custom resources
kubectl apply -f custom-resources.yaml

