# Fiskaly SRE Assignment

Take home assignment for Site Reliability Engineer role at fiskaly.

It is absolutely possible to run these tasks separately but I recommend following this README as it will allow you to create a docker image, set up EKS and run out image in the Kubernetes cluster in AWS.

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

## Task 3: Terraform Infrastructure Deployment (EKS)

We put task 3 before task 2 because we are going to use the EKS cluster to run our manifests in.

This Terraform stack provisions:

- A custom VPC with public/private subnets across 2-3 AZs
- An EKS cluster with one managed node group
- OIDC provider for IRSA

Task 3-oriented defaults in this stack:

- EKS managed node group is fixed to 4 nodes by default (`min=4`, `desired=4`, `max=4`).
- EKS API endpoint defaults to private access (`public_access=false`, `private_access=true`).
- Public endpoint CIDRs default to an empty list, so public control-plane exposure is opt-in.

It uses official modules only:

- `terraform-aws-modules/vpc/aws`
- `terraform-aws-modules/eks/aws`

For demo EC2 hosts used by Ansible testing, this stack uses Ubuntu + Amazon Linux to avoid additional RHEL licensing costs. In production, if RHEL is required, the corresponding Red Hat subscription/licensing and AWS Marketplace terms must be in place.

### Task 2 Prerequisites

- Terraform
- AWS CLI v2
- `kubectl`
- AWS credentials configured (for example via `aws configure` or SSO profile)
- Existing S3 bucket for Terraform backend state: `fiskaly-sre-assignment-terraform-backend`

### Configure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` if needed.

If you need temporary public API access for admin operations, explicitly set a tight allowlist CIDR (never `0.0.0.0/0`), for example:

```hcl
cluster_endpoint_public_access       = true
cluster_endpoint_private_access      = true
cluster_endpoint_public_access_cidrs = ["203.0.113.10/32"]
```

### Task 2 Deploy

```bash
terraform init
terraform apply
```

### Connect to EKS

Use Terraform outputs to avoid guessing names:

```bash
aws eks update-kubeconfig \
  --region "$(terraform output -raw region)" \
  --name "$(terraform output -raw cluster_name)"
```

Verify nodes:

```bash
kubectl get nodes
```

### Destroy

```bash
terraform destroy
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
- For local clusters (for example, kind): the `hello-world-web:latest` image available to cluster nodes.
- For EKS: push the image to ECR (or another reachable registry) and update `k8s/deployment.yaml` `image:` accordingly.

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

## Task 4: Ansible Playbook (Ubuntu + RedHat)

Playbook path:

- `ansible/playbook.yml`

What it does:

- Gathers system facts for all hosts.
- Updates package repositories.
- Upgrades packages.
- On Ubuntu/Debian:
  - Installs Apache (`apache2`).
  - Serves a static `Hello World` page at `/var/www/html/index.html`.
  - Restarts Apache when the page changes (via handler).
- On RedHat:
  - Installs MariaDB (`mariadb-server`).

### Run

Create an inventory file (example):

```ini
[ubuntu]
ubuntu-1 ansible_host=192.168.1.10 ansible_user=ubuntu

[redhat]
rhel-1 ansible_host=192.168.1.20 ansible_user=ec2-user

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

Execute the playbook:

```bash
ansible-playbook -i inventory.ini ansible/playbook.yml
```

## Bonus

I have implemented some bonus items.

### CI Quality Gates (GitHub Actions)

Workflow file:

- `.github/workflows/quality-gates.yml`

Triggers:

- `pull_request`
- `push` to `master` (`main`)
- `schedule` daily at `03:00 UTC`
- `workflow_dispatch`

Blocking checks on PR/push:

- `terraform-quality`
  - `terraform fmt -check -recursive terraform/`
  - `terraform -chdir=terraform init -backend=false -input=false`
  - `terraform -chdir=terraform validate`
  - `tflint --init`
  - `tflint --chdir=terraform --recursive`
- `k8s-quality`
  - `kubeconform -strict -summary k8s/*.yaml`
  - `kube-linter lint k8s --config .kube-linter.yaml`
- `ansible-quality`
  - `ansible-lint ansible/playbook.yml`
- `security-quality`
  - `docker build -t hello-world-web:ci .`
  - `trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 hello-world-web:ci`
  - `trivy config --severity HIGH,CRITICAL --exit-code 1 terraform/`

Nightly deep scan:

- Job: `nightly-trivy-fs` (runs on `schedule` and manual `workflow_dispatch`)
- Command:
  - `trivy fs --scanners vuln,misconfig,secret --severity HIGH,CRITICAL --exit-code 1 .`
- Report:
  - JSON artifact uploaded as `trivy-fs-report`.

Baseline tuning:

- `.kube-linter.yaml` enables all built-in checks and excludes only:
  - `latest-tag`
  - `default-service-account`
- `.tflint.hcl` enables the AWS ruleset plugin and module-aware linting.
- `.trivyignore` is intentionally not pre-populated; add only for confirmed false positives.

Recommended branch protection required checks:

- `terraform-quality`
- `k8s-quality`
- `ansible-quality`
- `security-quality`

### Run checks locally

You can run equivalent checks locally with:

```bash
terraform fmt -check -recursive terraform/
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
tflint --init --config=.tflint.hcl
tflint --chdir=terraform --recursive --config=../.tflint.hcl
kubeconform -strict -summary k8s/*.yaml
kube-linter lint k8s --config .kube-linter.yaml
ansible-lint ansible/playbook.yml
docker build -t hello-world-web:ci .
trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 hello-world-web:ci
trivy config --severity HIGH,CRITICAL --exit-code 1 terraform/
trivy fs --scanners vuln,misconfig,secret --severity HIGH,CRITICAL --exit-code 1 .
```
