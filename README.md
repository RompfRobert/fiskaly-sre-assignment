# fiskaly-sre-assignment

Take home assignment for Site Reliability Engineer role at fiskaly.

## Task 1: Docker Hello World Web App

This repository includes a minimal Python HTTP app that responds with `Hello World` on port `8080`.

### Build the image

```bash
docker build -t hello-world-web .
```

### Run the container

```bash
docker run --rm --name hello-world-web -p 8080:8080 hello-world-web
```

### Verify locally

```bash
curl http://localhost:8080
```

Expected response:

```text
Hello World
```

### Access from other devices on the same network

By default, `-p 8080:8080` publishes the container port on all host interfaces. To access it from another device on the same network, use:

```text
http://<your-host-ip>:8080
```

Example:

```text
http://192.168.1.42:8080
```

## Task 2: Kubernetes Deployment

The app from Task 1 is deployed with Kubernetes manifests in `k8s/`.

### What is included

- `k8s/deployment.yaml`: 2 replicas, probes, resources, and basic security settings.
- `k8s/hpa.yaml`: autoscaling from 2 to 4 replicas based on CPU load.
- `k8s/service.yaml`: ClusterIP service mapping `80 -> 8080`.
- `k8s/ingress.yaml`: ingress resource using `ingressClassName: nginx` for NGINX load balancing/routing.
- `k8s/namespace.yaml`: dedicated namespace (`hello-world`).

### Prerequisites

- A Kubernetes cluster (for example, kind, minikube, or EKS).
- NGINX Ingress Controller installed in the cluster.
- Metrics Server installed in the cluster (required by HPA).
- The `hello-world-web:latest` image available to cluster nodes.

Example for kind image loading:

```bash
kind load docker-image hello-world-web:latest
```

### Deploy

```bash
kubectl apply -f k8s/
```

### Validate

```bash
kubectl get deploy,pods,svc,hpa,ingress -n hello-world
```

Expected:

- Deployment starts with at least 2 replicas.
- HPA is configured with min 2 and max 4 replicas.
- Ingress is created with class `nginx`.

### Quick local check via service

```bash
kubectl port-forward -n hello-world svc/hello-world 8080:80
curl http://localhost:8080
```

Expected response:

```text
Hello World
```

### Security and resource settings included

- `runAsNonRoot: true`, non-root UID.
- `allowPrivilegeEscalation: false`.
- `capabilities.drop: ["ALL"]`.
- `readOnlyRootFilesystem: true`.
- CPU/memory requests and limits.
- Readiness and liveness probes.

### Optional: alternatives to NGINX load balancing

- `Traefik`: good for simple dynamic routing and lightweight setups.
- `HAProxy Ingress`: good when fine-grained traffic tuning or very high throughput is needed.
- Cloud-native ingress controllers (for example AWS ALB Controller): good when you want managed cloud L7 integration, IAM-native workflows, and native cloud load balancer features.
