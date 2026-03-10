# Terraform: AWS VPC + EKS

This Terraform stack provisions:

- A custom VPC with public/private subnets across 2-3 AZs
- An EKS cluster with one managed node group
- OIDC provider for IRSA
- Optional Ubuntu/Amazon Linux EC2 demo instances for Ansible testing

Task 3-oriented defaults in this stack:

- EKS managed node group is fixed to 4 nodes by default (`min=4`, `desired=4`, `max=4`).
- EKS API endpoint defaults to private access (`public_access=false`, `private_access=true`).
- Public endpoint CIDRs default to an empty list, so public control-plane exposure is opt-in.
- Demo EC2 counts default to `0`, so no extra EC2 instances are created unless explicitly requested.

It uses official modules only:

- `terraform-aws-modules/vpc/aws`
- `terraform-aws-modules/eks/aws`

## Prerequisites

- Terraform
- AWS CLI v2
- `kubectl`
- AWS credentials configured (for example via `aws configure` or SSO profile)

## Configure

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

If you want test hosts for the Ansible playbook, set optional demo EC2 counts in `terraform.tfvars`:

```hcl
ubuntu_instance_count = 1
amazon_linux_instance_count = 1
demo_instance_type    = "t3.micro"
demo_key_name         = "my-keypair"
demo_ssh_cidrs        = ["203.0.113.10/32"]
```

Notes:

- For this demo stack we use Amazon Linux instead of RHEL to avoid extra licensing costs.
- In production, if you require RHEL, ensure you have the appropriate Red Hat subscription/licensing and Marketplace terms accepted in your AWS account.
- If auto-discovery does not work in your account/region, set `ubuntu_ami_id` and `amazon_linux_ami_id` explicitly.

## Deploy

```bash
terraform init
terraform apply
```

## Connect to EKS

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

## Destroy

```bash
terraform destroy
```
