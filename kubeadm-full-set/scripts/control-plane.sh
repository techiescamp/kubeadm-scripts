#!/bin/bash
#
# Control plane setup

set -euxo pipefail

PUBLIC_IP_ACCESS="false"
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
CALICO_VERSION="v3.32.0"

if [[ ! -f /etc/kubernetes/admin.conf ]]; then
    # Pre-pull control plane images
    kubeadm config images pull

    # Initialize cluster
    if [[ "$PUBLIC_IP_ACCESS" == "false" ]]; then
        CONTROL_PLANE_PRIVATE_IP=$(ip addr show eth1 | awk '/inet / {print $2}' | cut -d/ -f1)
        kubeadm init \
            --apiserver-advertise-address="$CONTROL_PLANE_PRIVATE_IP" \
            --apiserver-cert-extra-sans="$CONTROL_PLANE_PRIVATE_IP" \
            --pod-network-cidr="$POD_CIDR" \
            --node-name "$NODENAME" \
            --ignore-preflight-errors Swap
    elif [[ "$PUBLIC_IP_ACCESS" == "true" ]]; then
        CONTROL_PLANE_PUBLIC_IP=$(curl -s ifconfig.me)
        kubeadm init \
            --control-plane-endpoint="$CONTROL_PLANE_PUBLIC_IP" \
            --apiserver-cert-extra-sans="$CONTROL_PLANE_PUBLIC_IP" \
            --pod-network-cidr="$POD_CIDR" \
            --node-name "$NODENAME" \
            --ignore-preflight-errors Swap
    else
        echo "ERROR: PUBLIC_IP_ACCESS must be 'true' or 'false'"
        exit 1
    fi
else
    echo "Kubernetes control plane already initialized; skipping kubeadm init"
fi

# kubeconfig for root
mkdir -p "$HOME/.kube"
cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
chown "$(id -u):$(id -g)" "$HOME/.kube/config"

# kubeconfig for vagrant user
mkdir -p /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# Export admin.conf to synced folder so host can use kubectl
cp /etc/kubernetes/admin.conf /vagrant/admin.conf
chmod 644 /vagrant/admin.conf

if ! kubectl get installation.operator.tigera.io default >/dev/null 2>&1; then
    # Install Calico CNI
    kubectl apply --server-side --force-conflicts -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/v1_crd_projectcalico_org.yaml"
    kubectl apply -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"

    curl -fsSL "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml" -o /tmp/calico-custom-resources.yaml
    # POD_CIDR matches Calico default (192.168.0.0/16); this keeps CIDR changes in one place.
    sed -i "s|cidr: 192.168.0.0/16|cidr: ${POD_CIDR}|g" /tmp/calico-custom-resources.yaml
    kubectl apply -f /tmp/calico-custom-resources.yaml
    rm -f /tmp/calico-custom-resources.yaml
else
    echo "Calico already installed; skipping CNI install"
fi

echo "Waiting for Calico node pods to be ready..."
kubectl wait --for=condition=ready pod \
    -l k8s-app=calico-node \
    -n calico-system \
    --timeout=300s || true

# Deploy metrics server
kubectl apply -f /vagrant/manifests/metrics-server.yaml

# Deploy sample nginx app
kubectl apply -f /vagrant/manifests/sample-app.yaml

# Generate node join command and save to synced folder
kubeadm token create --print-join-command > /vagrant/join.sh
chmod +x /vagrant/join.sh

echo ""
echo "============================================"
echo "  Control plane setup complete!"
echo "============================================"
echo ""
echo "  Cluster admin config: ./admin.conf"
echo "  Node join script:     ./join.sh"
echo ""
echo "  Use kubectl from your host:"
echo "    export KUBECONFIG=\$(pwd)/admin.conf"
echo "    kubectl get nodes"
echo ""
