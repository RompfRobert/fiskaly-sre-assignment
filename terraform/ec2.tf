locals {
  demo_instances_enabled = var.ubuntu_instance_count + var.amazon_linux_instance_count > 0
}

data "http" "operator_public_ip" {
  count = local.demo_instances_enabled && var.auto_detect_demo_ssh_cidr ? 1 : 0
  url   = var.demo_ssh_cidr_lookup_url
}

locals {
  auto_detected_demo_ssh_cidrs = local.demo_instances_enabled && var.auto_detect_demo_ssh_cidr ? ["${chomp(data.http.operator_public_ip[0].response_body)}/32"] : []
  effective_demo_ssh_cidrs     = distinct(compact(concat(var.demo_ssh_cidrs, local.auto_detected_demo_ssh_cidrs)))
}

data "aws_ami" "ubuntu" {
  count       = var.ubuntu_instance_count > 0 && var.ubuntu_ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "amazon_linux" {
  count       = var.amazon_linux_instance_count > 0 && var.amazon_linux_ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "demo_ec2" {
  count       = local.demo_instances_enabled ? 1 : 0
  name        = "${local.name_prefix}-demo-ec2-sg"
  description = "Security group for optional Ubuntu/Amazon Linux demo instances"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = local.effective_demo_ssh_cidrs
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-demo-ec2-sg"
  })
}

resource "aws_instance" "ubuntu" {
  count = var.ubuntu_instance_count

  ami                         = var.ubuntu_ami_id != "" ? var.ubuntu_ami_id : data.aws_ami.ubuntu[0].id
  instance_type               = var.demo_instance_type
  subnet_id                   = element(module.vpc.public_subnets, count.index % length(module.vpc.public_subnets))
  vpc_security_group_ids      = [aws_security_group.demo_ec2[0].id]
  key_name                    = var.demo_key_name != "" ? var.demo_key_name : null
  associate_public_ip_address = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ubuntu-${count.index + 1}"
    OS   = "ubuntu"
    Role = "ansible-demo"
  })
}

resource "aws_instance" "amazon_linux" {
  count = var.amazon_linux_instance_count

  ami                         = var.amazon_linux_ami_id != "" ? var.amazon_linux_ami_id : data.aws_ami.amazon_linux[0].id
  instance_type               = var.demo_instance_type
  subnet_id                   = element(module.vpc.public_subnets, count.index % length(module.vpc.public_subnets))
  vpc_security_group_ids      = [aws_security_group.demo_ec2[0].id]
  key_name                    = var.demo_key_name != "" ? var.demo_key_name : null
  associate_public_ip_address = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-amazon-linux-${count.index + 1}"
    OS   = "amazon-linux"
    Role = "ansible-demo"
  })
}