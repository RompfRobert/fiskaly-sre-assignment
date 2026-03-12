# Argo CD GitOps Bonus

This directory adds a GitOps deployment path for Task 2 resources.

Managed by Argo CD:

- hello-world app stack from `k8s/` (namespace, deployment, service, ingress, hpa, networkpolicy)
- ingress-nginx controller (Helm chart)
- Argo CD project guardrails (`platform` AppProject)

## Bootstrap

1. Install Argo CD:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version 7.7.16
```

1. Apply root app:

```bash
kubectl apply -f argocd/apps/root.yaml
```

1. Verify sync:

```bash
kubectl get applications -n argocd
```

1. Validate workload:

```bash
kubectl get deploy,svc,ing,hpa -n hello-world
kubectl get pods -n ingress-nginx
```

## Access dashboard (demo)

Use local port-forward for this assignment demo:

```bash
kubectl -n argocd port-forward svc/argocd-server 8443:443
```

Open `https://localhost:8443` and log in with `admin`.

Initial password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

## Notes

- Root app points to branch `dev`; update `targetRevision` if you deploy another branch.
- `ingress-nginx` is pinned to chart version `4.12.1` for reproducibility.
- Child apps use auto-sync, prune, and self-heal.
- Another option is exposing Argo CD through a domain with DNS and TLS; for this demo we keep things simple with local port-forward.

## Reset to fresh state

If your cluster has leftovers from previous Argo CD installation attempts (for example CRD or ClusterRole ownership conflicts during Helm install), run:

```bash
./argocd/bootstrap-reset.sh
```

For non-interactive execution:

```bash
./argocd/bootstrap-reset.sh --yes
```
