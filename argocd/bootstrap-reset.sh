#!/usr/bin/env bash
set -euo pipefail

# Reset this assignment's Argo CD footprint to a fresh state.
# This script removes Argo CD resources and related demo namespaces.

YES=false
if [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]]; then
  YES=true
fi

for cmd in kubectl helm; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' is not installed or not in PATH." >&2
    exit 1
  fi
done

CURRENT_CONTEXT="$(kubectl config current-context 2>/dev/null || true)"
if [[ -z "$CURRENT_CONTEXT" ]]; then
  echo "Error: no active kubectl context found." >&2
  exit 1
fi

echo "Current kubectl context: $CURRENT_CONTEXT"
echo "This will delete:"
echo "- Helm release: argocd (namespace argocd)"
echo "- Namespaces: argocd, ingress-nginx, hello-world (if present)"
echo "- Argo CD CRDs: *.argoproj.io (if present)"
echo "- Legacy cluster-scoped Argo RBAC/webhooks (if present)"

if [[ "$YES" != true ]]; then
  read -r -p "Continue? Type 'yes' to proceed: " CONFIRM
  if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "[1/6] Removing root app (best effort)"
kubectl delete -f argocd/apps/root.yaml --ignore-not-found >/dev/null 2>&1 || true

echo "[2/6] Uninstalling Helm release 'argocd' (best effort)"
if helm status argocd -n argocd >/dev/null 2>&1; then
  helm uninstall argocd -n argocd || true
fi

echo "[3/6] Deleting namespaces (best effort)"
for ns in argocd ingress-nginx hello-world; do
  kubectl delete namespace "$ns" --ignore-not-found --wait=false || true
done
kubectl wait --for=delete namespace/argocd --timeout=120s >/dev/null 2>&1 || true

echo "[4/6] Removing Argo CD CRDs (best effort)"
ARGO_CRDS=(
  applications.argoproj.io
  appprojects.argoproj.io
  applicationsets.argoproj.io
  argocdextensions.argoproj.io
)
for crd in "${ARGO_CRDS[@]}"; do
  kubectl delete crd "$crd" --ignore-not-found || true
done

echo "[5/6] Removing cluster-scoped Argo RBAC/webhooks (best effort)"
kubectl delete clusterrole,clusterrolebinding,validatingwebhookconfiguration,mutatingwebhookconfiguration \
  -l app.kubernetes.io/part-of=argocd --ignore-not-found >/dev/null 2>&1 || true

for name in \
  argocd-application-controller \
  argocd-server \
  argocd-dex-server \
  argocd-applicationset-controller \
  argocd-notifications-controller; do
  kubectl delete clusterrole "$name" --ignore-not-found >/dev/null 2>&1 || true
  kubectl delete clusterrolebinding "$name" --ignore-not-found >/dev/null 2>&1 || true
done

kubectl delete validatingwebhookconfiguration argocd-applicationset-controller --ignore-not-found >/dev/null 2>&1 || true
kubectl delete mutatingwebhookconfiguration argocd-applicationset-controller --ignore-not-found >/dev/null 2>&1 || true

echo "[6/6] Done"
echo "Cluster is back to a fresh Argo CD state for this assignment."
echo

echo "Reinstall commands:"
echo "  helm repo add argo https://argoproj.github.io/argo-helm"
echo "  helm repo update"
echo "  kubectl create namespace argocd"
echo "  helm upgrade --install argocd argo/argo-cd --namespace argocd --version 7.7.16"
echo "  kubectl apply -f argocd/apps/root.yaml"
