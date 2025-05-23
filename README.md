├── awx-microk8s-deploy
│   ├── README.md
│   ├── awx-deploy.sh
│   ├── awx-pod-debug.yaml
│   └── cleanup.sh

# README.md

# AWX on MicroK8s with Debug Tools

This repository contains a script to deploy **Ansible AWX 24.6.1** using the **AWX Operator** on **Ubuntu 22.04.5 LTS** with **MicroK8s**. It also includes utilities for troubleshooting stuck pods such as `awx-task`, particularly when they remain in `PodInitializing` state due to receptor certificate issues or misconfigured volumes.

## Features

- Deploys AWX via AWX Operator using a custom namespace (`awx`)
- Sets up PostgreSQL 15 automatically as the backend database
- Uses MicroK8s for a lightweight Kubernetes environment
- Handles necessary configmaps, secrets, and persistent volumes
- Includes a debug pod manifest to inspect receptor configuration and certificates
- Cleans up previous AWX and PostgreSQL resources to avoid conflicts on redeploy

## Prerequisites

- Ubuntu 22.04 or similar Linux system
- 2VPCU with minimum 4GB RAM
- MicroK8s installed and configured
- Internet access to pull images from `quay.io`

## Included Files

- `awx-deploy.sh`: Shell script to deploy AWX via the operator
- `awx-pod-debug.yaml`: A debug pod manifest to mount the receptor volumes for inspection
- `cleanup.sh`: Optional cleanup utility to remove AWX CRDs, deployments, and PVCs
- `README.md`: This documentation

## Troubleshooting

This setup includes a pod named `awx-task` which may sometimes fail to initialize due to issues like:

- Receptor TLS certificate generation hangs
- Incomplete secrets or configmap mappings
- Image pull delays or failures

You can use the `awx-pod-debug.yaml` file to launch a temporary pod with mounted volumes for manual inspection and debugging.

## Usage

### Deploy AWX

```bash
./awx-deploy.sh
```

### Clean up Deployment

```bash
./cleanup.sh
```

### Start Debug Pod

```bash
kubectl apply -f awx-pod-debug.yaml -n awx
kubectl exec -it awx-debug -- /bin/bash
```

## License

MIT License
