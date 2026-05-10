
#!/bin/bash
#
# Setup for control plane servers

set -euxo pipefail

# If you need public access to API server using the servers Public IP adress, change PUBLIC_IP_ACCESS to true.

PUBLIC_IP_ACCESS="false"
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
CALICO_VERSION="v3.32.0"

# Pull required images

sudo kubeadm config images pull

# Initialize kubeadm based on PUBLIC_IP_ACCESS

if [[ "$PUBLIC_IP_ACCESS" == "false" ]]; then
    
    CONTROL_PLANE_PRIVATE_IP=$(ip addr show eth1 | awk '/inet / {print $2}' | cut -d/ -f1)
    sudo kubeadm init --apiserver-advertise-address="$CONTROL_PLANE_PRIVATE_IP" --apiserver-cert-extra-sans="$CONTROL_PLANE_PRIVATE_IP" --pod-network-cidr="$POD_CIDR" --node-name "$NODENAME" --ignore-preflight-errors Swap

elif [[ "$PUBLIC_IP_ACCESS" == "true" ]]; then

    CONTROL_PLANE_PUBLIC_IP=$(curl ifconfig.me && echo "")
    sudo kubeadm init --control-plane-endpoint="$CONTROL_PLANE_PUBLIC_IP" --apiserver-cert-extra-sans="$CONTROL_PLANE_PUBLIC_IP" --pod-network-cidr="$POD_CIDR" --node-name "$NODENAME" --ignore-preflight-errors Swap

else
    echo "Error: PUBLIC_IP_ACCESS has an invalid value: $PUBLIC_IP_ACCESS"
    exit 1
fi

# Configure kubeconfig

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Install Calico Network Plugin

# Install Tigera Operator and CRDs
kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/v1_crd_projectcalico_org.yaml"
kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"

sleep 120

# Download custom resources
curl -fsSL "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml" -o custom-resources.yaml

# Get cluster CIDR from kube-controller-manager
CLUSTER_CIDR=$(kubectl -n kube-system get pod -l component=kube-controller-manager -o yaml | grep -i cluster-cidr | awk '{print $2}' | sed 's/--cluster-cidr=//')

if [ -z "$CLUSTER_CIDR" ]; then
    echo "Warning: Could not detect cluster CIDR, using configured pod CIDR $POD_CIDR"
    CLUSTER_CIDR="$POD_CIDR"
fi

echo "Using cluster CIDR: $CLUSTER_CIDR"

# Update CIDR in custom-resources.yaml
sed -i "s|cidr: 192.168.0.0/16|cidr: $CLUSTER_CIDR|g" custom-resources.yaml

# Apply custom resources
kubectl apply -f custom-resources.yaml
sleep 60
