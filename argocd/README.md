# Argo CD GitOps Bonus

This directory adds a GitOps deployment path for Task 2 resources.

Managed by Argo CD:

- hello-world app stack from `k8s/` (namespace, deployment, service, ingress, hpa, networkpolicy)
- ingress-nginx controller (Helm chart)
- Argo CD project guardrails (`platform` AppProject)

## Bootstrap

1. Install Argo CD:

kubectl create namespace argocd
kubectl apply -n argocd -f <https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml>

1. Apply root app:

kubectl apply -f argocd/apps/root.yaml

1. Verify sync:

kubectl get applications -n argocd

1. Validate workload:

kubectl get deploy,svc,ing,hpa -n hello-world
kubectl get pods -n ingress-nginx

## Notes

- Root app points to branch `dev`; update `targetRevision` if you deploy another branch.
- `ingress-nginx` is pinned to chart version `4.12.1` for reproducibility.
- Child apps use auto-sync, prune, and self-heal.
