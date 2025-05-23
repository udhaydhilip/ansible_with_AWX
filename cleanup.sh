#!/bin/bash

# cleanup.sh - Removes AWX and related resources from the 'awx' namespace in MicroK8s

NAMESPACE="awx"

echo "⚠️  This will delete all AWX resources and PVCs in the '$NAMESPACE' namespace."
read -p "Are you sure you want to continue? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "❌ Cleanup aborted."
  exit 1
fi

echo "🔍 Checking for namespace '$NAMESPACE'..."
if ! microk8s kubectl get ns "$NAMESPACE" &>/dev/null; then
  echo "✅ Namespace '$NAMESPACE' does not exist. Nothing to clean."
  exit 0
fi

echo "🧹 Deleting AWX custom resources..."
microk8s kubectl delete awx --all -n "$NAMESPACE"

echo "🧹 Deleting PVCs..."
microk8s kubectl delete pvc --all -n "$NAMESPACE"

echo "🧹 Deleting deployments, services, secrets, and configmaps..."
microk8s kubectl delete all --all -n "$NAMESPACE"
microk8s kubectl delete secret --all -n "$NAMESPACE"
microk8s kubectl delete configmap --all -n "$NAMESPACE"

echo "🧹 Deleting debug pod (if exists)..."
microk8s kubectl delete pod awx-debug -n "$NAMESPACE" --ignore-not-found

echo "🧹 Optionally deleting AWX Operator (CRDs, roles, etc.)..."
read -p "Do you also want to delete the AWX Operator and CRDs? [y/N]: " opconfirm
if [[ "$opconfirm" == "y" || "$opconfirm" == "Y" ]]; then
  echo "🗑️  Deleting AWX Operator and CRDs..."
  microk8s kubectl delete crds awxes.awx.ansible.com
  microk8s kubectl delete namespace "$NAMESPACE"
fi

echo "✅ Cleanup complete."
