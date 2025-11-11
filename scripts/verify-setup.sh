#!/bin/bash
#
# Verification script to check installed components and versions

set -euo pipefail

echo "=========================================="
echo "Kubernetes Cluster Component Verification"
echo "=========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Check Kubernetes components
echo "=== Kubernetes Components ==="
if command_exists kubeadm; then
    KUBEADM_VERSION=$(kubeadm version -o short 2>/dev/null || echo "unknown")
    print_status 0 "kubeadm: $KUBEADM_VERSION"
else
    print_status 1 "kubeadm: NOT INSTALLED"
fi

if command_exists kubelet; then
    KUBELET_VERSION=$(kubelet --version 2>/dev/null | awk '{print $2}' || echo "unknown")
    print_status 0 "kubelet: $KUBELET_VERSION"
    
    # Check kubelet status
    if systemctl is-active --quiet kubelet; then
        echo -e "  ${GREEN}→${NC} Status: Running"
    else
        echo -e "  ${YELLOW}→${NC} Status: Not running (normal before cluster init)"
    fi
else
    print_status 1 "kubelet: NOT INSTALLED"
fi

if command_exists kubectl; then
    KUBECTL_VERSION=$(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    print_status 0 "kubectl: $KUBECTL_VERSION"
else
    print_status 1 "kubectl: NOT INSTALLED"
fi

echo ""

# Check Container Runtime
echo "=== Container Runtime ==="
if command_exists containerd; then
    CONTAINERD_VERSION=$(containerd --version 2>/dev/null | awk '{print $3}' || echo "unknown")
    print_status 0 "containerd: $CONTAINERD_VERSION"
    
    # Check containerd status
    if systemctl is-active --quiet containerd; then
        echo -e "  ${GREEN}→${NC} Status: Running"
    else
        echo -e "  ${RED}→${NC} Status: Not running"
    fi
    
    # Check containerd socket
    if [ -S /run/containerd/containerd.sock ]; then
        echo -e "  ${GREEN}→${NC} Socket: /run/containerd/containerd.sock (exists)"
    else
        echo -e "  ${RED}→${NC} Socket: /run/containerd/containerd.sock (missing)"
    fi
else
    print_status 1 "containerd: NOT INSTALLED"
fi

if command_exists runc; then
    RUNC_VERSION=$(runc --version 2>/dev/null | head -n1 | awk '{print $3}' || echo "unknown")
    print_status 0 "runc: $RUNC_VERSION"
else
    print_status 1 "runc: NOT INSTALLED"
fi

echo ""

# Check crictl
echo "=== CRI Tools ==="
if command_exists crictl; then
    CRICTL_VERSION=$(crictl --version 2>/dev/null | awk '{print $3}' || echo "unknown")
    print_status 0 "crictl: $CRICTL_VERSION"
    
    # Check crictl config
    if [ -f /etc/crictl.yaml ]; then
        echo -e "  ${GREEN}→${NC} Config: /etc/crictl.yaml (exists)"
        RUNTIME_ENDPOINT=$(grep "runtime-endpoint" /etc/crictl.yaml | awk '{print $2}')
        echo -e "  ${GREEN}→${NC} Runtime endpoint: $RUNTIME_ENDPOINT"
    else
        echo -e "  ${YELLOW}→${NC} Config: /etc/crictl.yaml (missing)"
    fi
    
    # Try to get runtime info
    echo -e "\n  Testing crictl connectivity..."
    if sudo crictl info >/dev/null 2>&1; then
        echo -e "  ${GREEN}→${NC} crictl can communicate with containerd"
        
        # Get some basic stats
        RUNNING_CONTAINERS=$(sudo crictl ps -q 2>/dev/null | wc -l)
        TOTAL_IMAGES=$(sudo crictl images -q 2>/dev/null | wc -l)
        echo -e "  ${GREEN}→${NC} Running containers: $RUNNING_CONTAINERS"
        echo -e "  ${GREEN}→${NC} Total images: $TOTAL_IMAGES"
    else
        echo -e "  ${RED}→${NC} crictl cannot communicate with containerd"
    fi
else
    print_status 1 "crictl: NOT INSTALLED"
fi

echo ""

# Check CNI plugins
echo "=== CNI Plugins ==="
if [ -d /opt/cni/bin ]; then
    CNI_COUNT=$(ls -1 /opt/cni/bin 2>/dev/null | wc -l)
    print_status 0 "CNI plugins directory: /opt/cni/bin"
    echo -e "  ${GREEN}→${NC} Number of plugins: $CNI_COUNT"
    echo -e "  ${GREEN}→${NC} Plugins: $(ls /opt/cni/bin | tr '\n' ' ')"
else
    print_status 1 "CNI plugins directory: NOT FOUND"
fi

echo ""

# Check system configuration
echo "=== System Configuration ==="

# Check swap
if [ "$(swapon --show | wc -l)" -eq 0 ]; then
    print_status 0 "Swap: Disabled"
else
    print_status 1 "Swap: Enabled (should be disabled)"
fi

# Check kernel modules
if lsmod | grep -q overlay; then
    print_status 0 "Kernel module: overlay loaded"
else
    print_status 1 "Kernel module: overlay not loaded"
fi

if lsmod | grep -q br_netfilter; then
    print_status 0 "Kernel module: br_netfilter loaded"
else
    print_status 1 "Kernel module: br_netfilter not loaded"
fi

# Check sysctl settings
IP_FORWARD=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo "0")
if [ "$IP_FORWARD" = "1" ]; then
    print_status 0 "IP forwarding: Enabled"
else
    print_status 1 "IP forwarding: Disabled"
fi

BRIDGE_NF_IPTABLES=$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null || echo "0")
if [ "$BRIDGE_NF_IPTABLES" = "1" ]; then
    print_status 0 "Bridge netfilter (iptables): Enabled"
else
    print_status 1 "Bridge netfilter (iptables): Disabled"
fi

echo ""

# Check if cluster is initialized
echo "=== Cluster Status ==="
if [ -f /etc/kubernetes/admin.conf ]; then
    print_status 0 "Cluster: Initialized (admin.conf exists)"
    
    if command_exists kubectl && [ -f "$HOME/.kube/config" ]; then
        echo -e "\n  Cluster Info:"
        kubectl cluster-info 2>/dev/null || echo -e "  ${YELLOW}→${NC} Cannot connect to cluster"
        
        echo -e "\n  Node Status:"
        kubectl get nodes 2>/dev/null || echo -e "  ${YELLOW}→${NC} Cannot get nodes"
        
        echo -e "\n  System Pods:"
        kubectl get pods -n kube-system 2>/dev/null || echo -e "  ${YELLOW}→${NC} Cannot get pods"
    fi
else
    print_status 1 "Cluster: Not initialized yet"
fi

echo ""
echo "=========================================="
echo "Verification Complete"
echo "=========================================="
