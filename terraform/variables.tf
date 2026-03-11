variable "project_name" {
  description = "Project identifier used in naming and tags."
  type        = string
  default     = "sre-assignment"
}

variable "environment" {
  description = "Environment identifier used in naming and tags."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region where all resources will be created."
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "Optional explicit EKS cluster name. If empty, a name is derived from project and environment."
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "EKS Kubernetes control plane version."
  type        = string
  default     = "1.32"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of AZs/subnet pairs to create when availability_zones is not provided."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be either 2 or 3."
  }
}

variable "availability_zones" {
  description = "Optional explicit list of AZs. Leave empty to auto-select from the region."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.availability_zones) == 0 || (length(var.availability_zones) >= 2 && length(var.availability_zones) <= 3)
    error_message = "availability_zones must be empty or include 2 to 3 AZs."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateway(s) for private subnets."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT gateway by default to keep demo costs lower."
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Set to true to create one NAT gateway per AZ (higher availability and higher cost)."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API endpoint is publicly accessible."
  type        = bool
  default     = false
}

variable "cluster_endpoint_private_access" {
  description = "Whether the EKS API endpoint is privately accessible inside the VPC."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint."
  type        = list(string)
  default     = []
}

variable "node_group_name" {
  description = "Name of the default EKS managed node group."
  type        = string
  default     = "default"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS managed nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Capacity type for worker nodes: ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_min_size" {
  description = "Minimum size for the managed node group."
  type        = number
  default     = 4

  validation {
    condition     = var.node_group_min_size > 0
    error_message = "node_group_min_size must be greater than 0."
  }
}

variable "node_group_max_size" {
  description = "Maximum size for the managed node group."
  type        = number
  default     = 4

  validation {
    condition     = var.node_group_max_size > 0
    error_message = "node_group_max_size must be greater than 0."
  }
}

variable "node_group_desired_size" {
  description = "Desired size for the managed node group."
  type        = number
  default     = 4

  validation {
    condition     = var.node_group_desired_size >= var.node_group_min_size && var.node_group_desired_size <= var.node_group_max_size
    error_message = "node_group_desired_size must be between node_group_min_size and node_group_max_size."
  }
}

variable "node_group_disk_size" {
  description = "Root EBS volume size (GiB) for managed node group instances."
  type        = number
  default     = 20
}

variable "ubuntu_instance_count" {
  description = "Number of optional Ubuntu demo instances to create."
  type        = number
  default     = 0

  validation {
    condition     = var.ubuntu_instance_count >= 0
    error_message = "ubuntu_instance_count must be greater than or equal to 0."
  }
}

variable "amazon_linux_instance_count" {
  description = "Number of optional Amazon Linux demo instances to create."
  type        = number
  default     = 0

  validation {
    condition     = var.amazon_linux_instance_count >= 0
    error_message = "amazon_linux_instance_count must be greater than or equal to 0."
  }
}

variable "demo_instance_type" {
  description = "Instance type for optional Ubuntu/Amazon Linux demo instances."
  type        = string
  default     = "t3.micro"
}

variable "demo_key_name" {
  description = "Optional EC2 key pair name for SSH access to demo instances."
  type        = string
  default     = ""
}

variable "demo_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to optional demo instances."
  type        = list(string)
  default     = []
}

variable "ubuntu_ami_id" {
  description = "Optional explicit Ubuntu AMI ID. If empty, latest Ubuntu 22.04 LTS AMI is discovered."
  type        = string
  default     = ""
}

variable "amazon_linux_ami_id" {
  description = "Optional explicit Amazon Linux AMI ID. If empty, latest Amazon Linux 2023 AMI is discovered."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
