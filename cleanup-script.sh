#!/bin/bash

NAMESPACE="unused-resources-lab"

echo "===================================="
echo "Identifying unused resources in $NAMESPACE"
echo "===================================="

# -------- Identify Unused Deployments --------
echo "[CHECK] Unused Deployments (replicas=0):"
UNUSED_DEPLOYMENTS=$(kubectl get deployments -n $NAMESPACE -o json \
  | jq -r '.items[] | select(.spec.replicas==0) | .metadata.name')

echo "$UNUSED_DEPLOYMENTS"

# -------- Identify Completed Jobs --------
echo "[CHECK] Completed Jobs:"
UNUSED_JOBS=$(kubectl get jobs -n $NAMESPACE -o json \
  | jq -r '.items[] | select(.status.succeeded == .spec.completions) | .metadata.name')

echo "$UNUSED_JOBS"
# -------- Identify Unused Secrets --------
echo "[CHECK] Unused Secrets:"
USED_SECRETS=$(kubectl get pods -n $NAMESPACE -o json \
  | jq -r '.items[].spec.volumes[]?.secret.secretName')

UNUSED_SECRETS=$(kubectl get secrets -n $NAMESPACE -o json \
  | jq -r '.items[].metadata.name' \
  | grep -v -F -f <(echo "$USED_SECRETS"))

echo "$UNUSED_SECRETS"

echo "===================================="
echo "Starting cleanup of identified unused resources"
echo "===================================="

# -------- Cleanup Phase --------
kubectl delete deployment $UNUSED_DEPLOYMENTS -n $NAMESPACE --ignore-not-found
kubectl delete job $UNUSED_JOBS -n $NAMESPACE --ignore-not-found
kubectl delete configmap $UNUSED_CONFIGMAPS -n $NAMESPACE --ignore-not-found
kubectl delete secret $UNUSED_SECRETS -n $NAMESPACE --ignore-not-found

echo "[INFO] Cleanup completed"
