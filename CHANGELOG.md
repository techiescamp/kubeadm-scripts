# Changelog

## 2026-04-30 - Update to Kubernetes v1.36

### Changes Made:
- **Kubernetes Version**: Updated from v1.34 to v1.36
- **Container Runtime**: Switched from containerd to CRI-O v1.36
- **crictl**: Updated from v1.34.0 to v1.36.0
- **Network Plugin**: Updated Calico manifests to v3.32.0 for Kubernetes v1.36 compatibility

### Technical Details:
- **Kubernetes v1.36.0-1.1**
- **crictl v1.36.0**
- **CRI-O v1.36**
- **Calico v3.32.0**
- **runc v1.4.0**
- Updated `scripts/common.sh` with new version variables and CRI-O installation.


## 2025-11-11 - Migration to containerd

### Changes Made:
- **Kubernetes Version**: Updated from v1.30 to v1.34
- **Container Runtime**: Migrated from CRI-O to containerd
- **crictl**: Added crictl v1.34.0 with proper containerd configuration

### Technical Details:

#### Containerd Installation:
- containerd v1.7.22
- runc v1.2.2
- CNI plugins v1.6.0
- SystemdCgroup enabled for proper cgroup management

#### crictl Configuration:
- Installed crictl v1.34.0
- Configured to use containerd socket: `unix:///run/containerd/containerd.sock`
- Configuration file: `/etc/crictl.yaml`

#### Usage:
After running the setup script, you can use crictl commands:
```bash
sudo crictl ps        # List running containers
sudo crictl images    # List images
sudo crictl pods      # List pods
sudo crictl info      # Show runtime info
```

### Files Modified:
- `scripts/common.sh` - Complete rewrite of container runtime section
