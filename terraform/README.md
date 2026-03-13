# Terraform: AWS VPC + EKS

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

## Prerequisites

- Terraform (version `>= 1.10` for native S3 lockfile support)
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
