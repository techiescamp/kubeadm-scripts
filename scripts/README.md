# Kubeadm Cluster Setup Scripts

## Overview

These scripts automate the setup of a Kubernetes cluster using kubeadm with CRI-O as the container runtime.

## Components & Versions

- **Kubernetes**: v1.36
- **Container Runtime**: CRI-O 1.36.0
- **crictl**: v1.36.0
- **Network Plugin**: Calico v3.32.0

## Scripts

### common.sh
Common setup script for all nodes (control plane and nodes). This script:
- Disables swap
- Configures kernel modules (overlay, br_netfilter)
- Sets up networking parameters
- Installs CRI-O runtime
- Installs and configures crictl
- Installs kubelet, kubeadm, and kubectl

### control-plane.sh
Control plane setup script. This script:
- Pulls required Kubernetes images
- Initializes the control plane using kubeadm
- Configures kubeconfig
- Installs Calico network plugin

### verify-setup.sh
Verification script to check installed components and their versions after setup.

## Usage

### 1. Setup Control Plane Node

```bash
# Run common setup
sudo bash common.sh

# Initialize control plane
sudo bash control-plane.sh
```

### 2. Setup Nodes

```bash
# Run common setup on each node
sudo bash common.sh

# Join the cluster using the command from control plane output
sudo kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

### 3. Verify Setup

```bash
# Check all component versions
bash verify-setup.sh
```

## Post-Installation

### Using crictl

crictl is configured to work with CRI-O. Common commands:

```bash
# List running containers
sudo crictl ps

# List all containers (including stopped)
sudo crictl ps -a

# List images
sudo crictl images

# List pods
sudo crictl pods

# Get runtime info
sudo crictl info

# Inspect a container
sudo crictl inspect <container-id>

# View container logs
sudo crictl logs <container-id>

# Execute command in container
sudo crictl exec -it <container-id> /bin/sh
```

### Using kubectl

```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes
kubectl get pods -A

# Check component status
kubectl get componentstatuses
```

## Troubleshooting

### Check CRI-O status
```bash
sudo systemctl status crio
sudo journalctl -u crio -f
```

### Check kubelet status
```bash
sudo systemctl status kubelet
sudo journalctl -u kubelet -f
```

### Verify CRI-O configuration
```bash
sudo cat /etc/crio/crio.conf
```

### Verify crictl configuration
```bash
cat /etc/crictl.yaml
```

## Network Configuration

- **Pod Network CIDR**: 192.168.0.0/16 (Calico default)
- **Network Plugin**: Calico

## Important Notes

- Swap must be disabled for Kubernetes to work properly
- The scripts use `eth1` interface for node IP configuration (modify if your interface is different)
- CRI-O is used as the container runtime
- All Kubernetes components are held from automatic updates using `apt-mark hold`
