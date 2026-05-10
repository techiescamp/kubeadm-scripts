#!/bin/bash
#
# Node setup - waits for control plane join command then joins the cluster

set -euxo pipefail

TIMEOUT=300
ELAPSED=0

if [[ -f /etc/kubernetes/kubelet.conf ]]; then
    echo "Node already joined cluster; skipping kubeadm join"
    exit 0
fi

echo "Waiting for control plane to generate join command (/vagrant/join.sh)..."
while [ ! -f /vagrant/join.sh ]; do
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "ERROR: Timed out after ${TIMEOUT}s waiting for /vagrant/join.sh"
        echo "Check that the control plane provisioned successfully."
        exit 1
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

echo "Join command found - joining cluster..."
bash /vagrant/join.sh

echo ""
echo "============================================"
echo "  Node $(hostname) joined cluster!"
echo "============================================"
