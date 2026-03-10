output "region" {
  description = "AWS region used for this deployment."
  value       = var.region
}

output "vpc_id" {
  description = "VPC ID created for the EKS cluster."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by EKS nodes."
  value       = module.vpc.private_subnets
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version."
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN created for IRSA."
  value       = module.eks.oidc_provider_arn
}

output "oidc_issuer_url" {
  description = "EKS OIDC issuer URL."
  value       = module.eks.cluster_oidc_issuer_url
}

output "node_group_names" {
  description = "Created EKS managed node group names."
  value       = try([for ng in module.eks.eks_managed_node_groups : ng.node_group_name], keys(module.eks.eks_managed_node_groups))
}

output "ubuntu_instance_ids" {
  description = "Instance IDs of optional Ubuntu demo instances."
  value       = aws_instance.ubuntu[*].id
}

output "ubuntu_instance_public_ips" {
  description = "Public IPs of optional Ubuntu demo instances."
  value       = aws_instance.ubuntu[*].public_ip
}

output "amazon_linux_instance_ids" {
  description = "Instance IDs of optional Amazon Linux demo instances."
  value       = aws_instance.amazon_linux[*].id
}

output "amazon_linux_instance_public_ips" {
  description = "Public IPs of optional Amazon Linux demo instances."
  value       = aws_instance.amazon_linux[*].public_ip
}
