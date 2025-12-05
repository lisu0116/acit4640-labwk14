resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "lab-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "lab-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "lab-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "lab-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web_sg" {
  name        = "lab-web-sg"
  description = "Allow SSH & HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  tags = {
    Name = "lab-web-sg"
  }
}

data "aws_ami" "debian_13" {
  most_recent = true
  owners      = ["136693071363"] # Debian official in many regions; adjust if needed

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]
  }
}

data "aws_ami" "rocky_linux" {
  most_recent = true

  owners = ["aws-marketplace"]  # Works in every region

  filter {
    name   = "name"
    values = ["Rocky-9-*-x86_64-*"]
  }

  filter {
    name   = "architecture"
    values s= ["x86_64"]
  }
}


resource "aws_instance" "web" {
  ami                    = data.aws_ami.debian_13.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.ssh_key_name

  tags = {
    Name = "Web"
    Role = "Web"
  }
}

resource "aws_instance" "database" {
  ami                    = data.aws_ami.rocky_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.ssh_key_name

  tags = {
    Name = "Database"
    Role = "Database"
  }
}
