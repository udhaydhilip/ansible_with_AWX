#!/bin/bash

set -e

echo "[*] Updating system packages..."
apt update && apt upgrade -y

echo "[*] Installing prerequisites..."
apt install -y ansible curl git make jq

echo "[*] Installing MicroK8s via snap..."
snap install microk8s --classic

echo "[*] Adding current user to microk8s group..."
usermod -a -G microk8s $USER
chown -f -R $USER ~/.kube

echo "[*] Waiting for MicroK8s to be ready..."
microk8s status --wait-ready

echo "[*] Enabling MicroK8s addons (dns, storage, ingress)..."
microk8s enable dns
microk8s enable storage
microk8s enable ingress

echo "[*] Creating alias for kubectl..."
snap alias microk8s.kubectl kubectl

echo "[*] Cleaning up previous awx-operator repo if exists..."
rm -rf awx-operator

echo "[*] Cloning AWX Operator repository..."
git clone https://github.com/ansible/awx-operator.git
cd awx-operator

# Fetch latest tags and checkout a stable release
LATEST_TAG=$(git tag -l | grep -E '^.*[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
echo "[*] Checking out latest tag: $LATEST_TAG"
git checkout "$LATEST_TAG"

echo "[*] Deploying AWX Operator..."
KUBECTL='/snap/bin/microk8s.kubectl' make deploy

echo "[*] Waiting for AWX Operator to be ready..."
until microk8s kubectl get pods -n awx | grep -q '1/1\|2/2'; do
    echo "...waiting for all pods to become ready..."
    sleep 10
done

echo "[*] Creating AWX instance manifest..."
cat <<EOF | microk8s kubectl apply -f -
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: nodeport
  ingress_type: none
  hostname: awx.local
  replicas: 1
EOF

echo "[*] Waiting for AWX pods to be ready..."
while [[ $(microk8s kubectl get pods -n awx | grep -c "Running") -lt 3 ]]; do
    echo "...waiting for all pods to become ready..."
    sleep 10
done

echo "[*] Getting NodePort of AWX Service..."
AWX_PORT=$(microk8s kubectl get svc -n awx awx-service -o jsonpath='{.spec.ports[0].nodePort}')
echo "[✓] AWX should be accessible at: http://<your-server-ip>:$AWX_PORT"

echo "[*] Getting AWX admin password..."
AWX_PWD=$(microk8s kubectl get secret -n awx awx-admin-password -o jsonpath="{.data.password}" | base64 --decode)
echo "AWX Admin Username: admin"
echo "AWX Admin Password: $AWX_PWD"

echo "[✓] AWX installation complete!"
