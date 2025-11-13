# ==========================
# Terraform base configuration
# ==========================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ==========================
# AWS Provider
# ==========================
provider "aws" {
  region = var.region
}

# ==========================
# Default VPC
# ==========================
data "aws_vpc" "default" {
  default = true
}

# ==========================
# Subnets that auto-assign public IPv4
# ==========================
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# ==========================
# S3 Bucket for frontend
# ==========================
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend"

  tags = {
    Project = var.project_name
  }
}

# ==========================
# AMI: Amazon Linux 2023
# ==========================
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  owners = ["137112412989"]
}

# ==========================
# S3 Website configuration
# ==========================
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

# ==========================
# S3 Public access block
# ==========================
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ==========================
# S3 Bucket policy
# ==========================
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

# ==========================
# Key Pair
# ==========================
resource "aws_key_pair" "lab_key" {
  key_name   = "${var.project_name}-key"
  public_key = file("${path.module}/../mykey.pub")
}

# ==========================
# CloudWatch Log Group
# ==========================
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/ec2/${var.project_name}-api"
  retention_in_days = 7

  tags = {
    Project = var.project_name
  }
}

# ==========================
# Security Group
# ==========================
resource "aws_security_group" "api_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH + HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["181.46.139.213/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================
# IAM Role for EC2
# ==========================
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# ==========================
# IAM Policy (CloudWatch Logs)
# ==========================
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.project_name}-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "*"
    }]
  })
}

# ==========================
# IAM Instance Profile
# ==========================
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ==========================
# EC2 Instance (API Server)
# ==========================
resource "aws_instance" "api_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.api_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = aws_key_pair.lab_key.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    dnf update -y
    dnf install -y git
    dnf install -y nodejs npm

    mkdir -p /home/ec2-user/app
    cd /home/ec2-user/app

    git clone https://github.com/agarciaprogrammer/hello-devops-lab1.git
    cd hello-devops-lab1/api

    npm install
    nohup npm start > /home/ec2-user/server.log 2>&1 &
  EOF

  tags = {
    Name = "${var.project_name}-ec2"
  }
}
