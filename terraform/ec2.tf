locals {
  demo_instances_enabled = var.ubuntu_instance_count + var.rhel_instance_count > 0
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

data "aws_ami" "rhel" {
  count       = var.rhel_instance_count > 0 && var.rhel_ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["309956199498"] # Red Hat

  filter {
    name   = "name"
    values = ["RHEL-9.*_HVM-*-x86_64-*-GP3"]
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
  description = "Security group for optional Ubuntu/RHEL demo instances"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.demo_ssh_cidrs
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

resource "aws_instance" "rhel" {
  count = var.rhel_instance_count

  ami                         = var.rhel_ami_id != "" ? var.rhel_ami_id : data.aws_ami.rhel[0].id
  instance_type               = var.demo_instance_type
  subnet_id                   = element(module.vpc.public_subnets, count.index % length(module.vpc.public_subnets))
  vpc_security_group_ids      = [aws_security_group.demo_ec2[0].id]
  key_name                    = var.demo_key_name != "" ? var.demo_key_name : null
  associate_public_ip_address = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rhel-${count.index + 1}"
    OS   = "rhel"
    Role = "ansible-demo"
  })
}