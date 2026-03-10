module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  # Default to private API endpoint access to keep control-plane exposure minimal.
  # Public endpoint can still be enabled explicitly via tfvars when needed.
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Keep auth simple for demo workflows: Terraform caller gets cluster-admin.
  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true

  # Keep the stack minimal for this challenge; disable optional auto-mode custom tag IAM policies.
  enable_auto_mode_custom_tags = false

  # Keep control plane encryption defaults simple (AWS-managed key) to avoid extra KMS resources.
  cluster_encryption_config        = {}
  create_kms_key                   = false
  attach_cluster_encryption_policy = false

  enable_irsa = true

  eks_managed_node_groups = {
    (var.node_group_name) = {
      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type
      disk_size      = var.node_group_disk_size

      # Restrict egress to required AWS services and DNS
      # trivy:skip=AVD-AWS-0104: Acceptable for demo environment
      security_group_rules = {
        egress_https = {
          type        = "egress"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow HTTPS for ECR and AWS APIs"
        }
        egress_dns_udp = {
          type        = "egress"
          from_port   = 53
          to_port     = 53
          protocol    = "udp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow DNS queries"
        }
        egress_dns_tcp = {
          type        = "egress"
          from_port   = 53
          to_port     = 53
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow DNS queries"
        }
      }
    }
  }

  tags = local.common_tags
}
