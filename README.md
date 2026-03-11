# Fiskaly SRE Assignment

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

### Approach and reasoning

- I implemented a minimal Python HTTP server using the standard library to keep the image tiny and dependency-free.

- Assumptions: the app will be run in a local/network Docker host with port 8080 reachable; no production TLS or auth required for this exercise.

- Trade-offs: the stdlib server is simple but single-threaded and not production-grade; for production I'd use a proper web server (e.g., gunicorn/uvicorn or nginx) and multi-stage builds to minimize image size.

## Task 3: Terraform Infrastructure Deployment (EKS)

We put task 3 before task 2 because we are going to use the EKS cluster to run our manifests in. You don't have to do this in this order if you don't want to, I just thought to combine the 2 steps since they are complimentary.

This Terraform stack provisions:

- A custom VPC with public/private subnets across 2-3 AZs
- An EKS cluster with one managed node group
- OIDC provider for IRSA

Task 3-oriented defaults in this stack:

- EKS managed node group is fixed to 4 nodes by default (`min=4`, `desired=4`, `max=4`).
- EKS API endpoint defaults to private access (`public_access=false`, `private_access=true`).
- Public endpoint CIDRs default to an empty list, so public control-plane exposure is opt-in.

It uses official modules for core infrastructure:

- `terraform-aws-modules/vpc/aws`
- `terraform-aws-modules/eks/aws`

Optional demo EC2 resources for Ansible testing are defined with native AWS Terraform resources.

For demo EC2 hosts used by Ansible testing, this stack uses Ubuntu + Amazon Linux to avoid additional RHEL licensing costs. In production, if RHEL is required, the corresponding Red Hat subscription/licensing and AWS Marketplace terms must be in place.

### Approach and reasoning

- **EKS over self-managed**: EKS provides a managed control plane and OIDC integration (IRSA) out of the box.
- **Official modules**: terraform-aws-modules maintain best practices and reduce boilerplate.
- **Private endpoint by default**: Restricts unauthenticated exposure but does not require bastion/VPN for authenticated admin access.
- **Fixed 4 nodes**: Matches assignment requirement; production would use auto-scaling groups.
- **Multi-AZ subnets**: High availability across zones; handles AZ failures.

### Assumptions

- Single AWS region (eu-central-1 default).
- Operator has admin IAM permissions.
- No multi-region disaster recovery needed.
- No existing VPC/EKS (fresh stack).

### Trade-offs and alternatives

- **Fixed node count**: Simple, predictable; production should use auto-scaling.
- **Ubuntu + Amazon Linux for demo**: Avoids RHEL licensing. Production would use RHEL per compliance requirements.
- **Alternatives**: GKE (Google Cloud) simpler OAuth integration; self-managed Kubernetes for maximum control at operational cost.

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

### Approach and reasoning

- **Static manifests**: Simple, transparent, and easy to version control. Ideal for learning and small deployments.
- **Namespace isolation**: Dedicated namespace keeps resources organized and simplifies multi-tenancy scenarios.
- **HPA for autoscaling**: Scales replicas based on CPU metrics; matches the requirement to scale from 2 to 4 replicas under load.
- **Health probes**: Readiness and liveness probes improve availability by automatically restarting unhealthy pods and removing unready pods from service.
- **Security-first**: Non-root user, dropped capabilities, read-only filesystem, and resource limits reduce attack surface.
- **NGINX Ingress**: Standard, widely-available, performs layer 7 routing and load balancing.

### Assumptions

- Kubernetes cluster is healthy and accessible via `kubectl`.
- Operator has permissions to install Helm charts or apply manifests.
- Container image is available to the cluster (pushed to ECR for EKS, or loaded locally for kind/minikube).
- Cluster has sufficient resources to run at least 4 pod replicas.

### Trade-offs and alternatives

- **Static manifests vs Helm**: Manifests are simpler and require no templating engine, but Helm adds reusability and parameterization for multi-environment deployments.
- **Static manifests vs GitOps (ArgoCD)**: ArgoCD enables continuous deployment from Git, automatic reconciliation, and audit trails—better for large teams and frequent releases, but adds operational overhead.
- **NGINX Ingress vs alternatives**: See "Optional: alternatives to NGINX load balancing" section below.
- **HPA vs manual scaling**: HPA is reactive and automatic; production often layers on predictive scaling or event-driven scaling for predictable load patterns.
- **ClusterIP service vs LoadBalancer**: ClusterIP + Ingress is standard and cost-effective; LoadBalancer directly exposes the service but requires more managed load balancers.

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

### Approach and reasoning

- **Single play for mixed fleet**: One playbook targets `all` hosts and uses OS-family conditionals to keep logic centralized and easy to review.
- **Facts-driven branching**: `ansible_facts['os_family']` and `ansible_facts['pkg_mgr']` decide whether `apt`, `dnf`, or `yum` tasks run.
- **Idempotent package/service management**: Built-in modules ensure repeated runs converge to the same desired state.
- **Handler-based Apache restart**: Apache restarts only when `index.html` changes, avoiding unnecessary service disruption.
- **Service readiness included**: Apache and MariaDB are both enabled and started to ensure hosts are immediately usable after one run.

### Assumptions

- SSH connectivity to all target hosts is available and inventory variables are correct.
- Remote users have sudo privileges (`become: true`).
- Debian-family hosts use `apache2` package/service naming.
- RedHat-family hosts provide `mariadb-server` package and `mariadb` service.
- Managed hosts have access to configured package repositories.

### Trade-offs and alternatives

- **One playbook vs split role/playbooks**: A single file is simpler for this assignment; roles would improve reuse for larger environments.
- **In-place package upgrades**: Easy to operate but can introduce unplanned version changes; production teams often use staged rollouts and version pinning.
- **OS-family conditionals**: Flexible for mixed fleets, but logic grows over time; inventory-group based plays can be clearer at scale.
- **Static content via `copy`**: Works for a simple page; templates (`ansible.builtin.template`) are better when host-specific config is needed.
- **Community alternatives**: Collections/roles from Ansible Galaxy can speed up setup, but custom tasks provide clearer control and fewer external dependencies.

### SSH key setup (for EC2 demo hosts)

Use your own EC2 key pair and matching private key file.

Create a key pair (example):

```bash
aws ec2 create-key-pair \
  --region eu-central-1 \
  --key-name sre-assignment-demo \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/sre-assignment-demo.pem

chmod 600 ~/.ssh/sre-assignment-demo.pem
```

Then set the same key name in `terraform/terraform.tfvars` and allow SSH from your current public IP:

```hcl
ubuntu_instance_count      = 1
amazon_linux_instance_count = 1
demo_key_name             = "sre-assignment-demo"
demo_ssh_cidrs            = ["203.0.113.10/32"]
```

Note: demo EC2 instances are disabled by default (`ubuntu_instance_count = 0`, `amazon_linux_instance_count = 0`).

### Generate inventory automatically

After `terraform apply`, generate `inventory.ini` from Terraform outputs:

```bash
scripts/generate-inventory.sh > inventory.ini
```

Or write directly to file:

```bash
scripts/generate-inventory.sh inventory.ini
```

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

### Reviewer quick validation steps

1. Configure and create demo instances in `terraform/terraform.tfvars` (counts, `demo_key_name`, `demo_ssh_cidrs`).
2. Apply Terraform:

```bash
cd terraform
terraform init
terraform apply
```

3. Generate inventory:

```bash
cd ..
scripts/generate-inventory.sh > inventory.ini
```

4. Validate SSH connectivity before running the playbook:

```bash
ansible all -i inventory.ini -m ping
```

5. Run playbook:

```bash
ansible-playbook -i inventory.ini ansible/playbook.yml
```

6. Verify expected outcomes:

```bash
ansible ubuntu -i inventory.ini -m shell -a 'curl -s http://localhost/'
ansible redhat -i inventory.ini -m shell -a 'systemctl is-active mariadb'
```

7. Clean up resources:

```bash
cd terraform
terraform destroy
```
