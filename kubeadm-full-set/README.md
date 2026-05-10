# Local kubeadm Cluster With Vagrant

This project creates a fully automated local Kubernetes cluster with kubeadm. Run one command and Vagrant will create the control plane, initialize kubeadm, install CRI-O, install Calico, deploy metrics-server and a sample app, generate the join command, and join the worker nodes.

## Topology

| VM | Hostname | IP | Role | Memory | CPU |
| --- | --- | --- | --- | --- | --- |
| control-plane | control-plane-node | 10.0.0.10 | Kubernetes control plane | 4096 MB | 2 |
| node01 | node01 | 10.0.0.11 | Worker | 2048 MB | 2 |
| node02 | node02 | 10.0.0.12 | Worker | 2048 MB | 2 |

## Requirements

- Vagrant
- VirtualBox
- kubectl on your host machine, optional but recommended
- At least 8 GB free RAM

Run all Vagrant commands as your normal user. Do not use `sudo vagrant ...`.

## Start The Cluster

From this directory:

```sh
cd kubeadm-scripts/kubeadm-full-set
vagrant up
```

That command performs the full setup:

- Creates one control-plane VM and two worker VMs
- Installs CRI-O, kubelet, kubeadm, kubectl, crictl, and jq on every VM
- Runs `kubeadm init` on the control plane
- Installs Calico CNI
- Writes `admin.conf` to this directory
- Writes `join.sh` to this directory
- Automatically joins `node01` and `node02`
- Applies `../manifests/metrics-server.yaml`
- Applies `../manifests/sample-app.yaml`

## Verify

Use the exported kubeconfig:

```sh
export KUBECONFIG="$(pwd)/admin.conf"
kubectl get nodes -o wide
kubectl get pods -A
kubectl get svc nginx-service
```

Expected nodes:

```text
control-plane-node   Ready
node01               Ready
node02               Ready
```

The sample app is exposed as a NodePort service on port `32000`.

## Useful Commands

SSH into a VM:

```sh
vagrant ssh control-plane
vagrant ssh node01
vagrant ssh node02
```

Check VM status:

```sh
vagrant status
```

Re-run provisioning:

```sh
vagrant provision
```

Stop the cluster:

```sh
vagrant halt
```

Destroy and rebuild from scratch:

```sh
vagrant destroy -f
rm -f admin.conf join.sh
vagrant up
```

## File Layout

- `Vagrantfile`: VM definitions, networking, shared folders, and provisioning order
- `scripts/common.sh`: packages and OS configuration used by every VM
- `scripts/control-plane.sh`: kubeadm init, Calico, metrics-server, sample app, and join command generation
- `scripts/node.sh`: waits for `join.sh` and joins each worker node
- `../manifests/metrics-server.yaml`: metrics-server manifest
- `../manifests/sample-app.yaml`: sample nginx NodePort app

## Troubleshooting

If Vagrant reports a VirtualBox UID mismatch, stop and rerun the command without `sudo`.

If VirtualBox reports inaccessible stale VMs, remove those stale entries from VirtualBox Manager or with `VBoxManage unregistervm <uuid> --delete`, then run `vagrant up` again.

If workers do not join, check that `join.sh` exists in this directory and that the control plane is running:

```sh
vagrant status
vagrant ssh control-plane
kubectl get nodes
```
