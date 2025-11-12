# Kubeadm Cluster Setup Scripts

## Overview

These scripts automate the setup of a Kubernetes cluster using kubeadm with containerd as the container runtime.

## Components & Versions

- **Kubernetes**: v1.34
- **Container Runtime**: containerd v2.2.0
- **runc**: v1.3.3
- **CNI Plugins**: v1.6.0 (optional, commented out - Calico provides its own)
- **crictl**: v1.34.0
- **Network Plugin**: Calico

## Scripts

### common.sh
Common setup script for all nodes (control plane and worker nodes). This script:
- Disables swap
- Configures kernel modules (overlay, br_netfilter)
- Sets up networking parameters
- Installs containerd runtime
- Installs and configures crictl
- Installs kubelet, kubeadm, and kubectl

### master.sh
Control plane (master) node setup script. This script:
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
sudo bash master.sh
```

### 2. Setup Worker Nodes

```bash
# Run common setup on each worker node
sudo bash common.sh

# Join the cluster using the command from master node output
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

### 3. Verify Setup

```bash
# Check all component versions
bash verify-setup.sh
```

## Post-Installation

### Using crictl

crictl is configured to work with containerd. Common commands:

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

### Check containerd status
```bash
sudo systemctl status containerd
sudo journalctl -u containerd -f
```

### Check kubelet status
```bash
sudo systemctl status kubelet
sudo journalctl -u kubelet -f
```

### Verify containerd configuration
```bash
sudo cat /etc/containerd/config.toml
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
- SystemdCgroup is enabled in containerd for proper cgroup management
- All Kubernetes components are held from automatic updates using `apt-mark hold`
