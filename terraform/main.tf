locals {
  project_name = "lab_week_14"
}

# Debian 13 AMI (web server)
data "aws_ami" "debian_13" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "web" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name    = "project_vpc"
    Project = local.project_name
  }
}

# Subnet
resource "aws_subnet" "web" {
  vpc_id                  = aws_vpc.web.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "web-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "web_gw" {
  vpc_id = aws_vpc.web.id

  tags = {
    Name = "web-igw"
  }
}

# Route table
resource "aws_route_table" "web" {
  vpc_id = aws_vpc.web.id

  tags = {
    Name = "web-rt"
  }
}

# Default route
resource "aws_route" "web_default" {
  route_table_id         = aws_route_table.web.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.web_gw.id
}

# Route table association
resource "aws_route_table_association" "web_assoc" {
  subnet_id      = aws_subnet.web.id
  route_table_id = aws_route_table.web.id
}

# Security group
resource "aws_security_group" "web" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.web.id

  tags = {
    Name = "web-sg"
  }
}

# Allow SSH
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# Allow HTTP
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# Allow all egress
resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

# Web server (Debian 13)
resource "aws_instance" "web" {
  ami                    = data.aws_ami.debian_13.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.web.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.ssh_key_name

  tags = {
    Name = "Web"
    Role = "Web"
  }
}

resource "aws_instance" "database" {
  ami                    = "ami-093bd987f8e53e1f2"  
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.web.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.ssh_key_name

  tags = {
    Name = "Database"
    Role = "Database"
  }
}

