terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

############################
# VPC y red
############################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "${var.project_name}-private" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  tags          = { Name = "${var.project_name}-nat" }
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

############################
# Security Groups
############################

resource "aws_security_group" "frontend_sg" {
  name   = "${var.project_name}-frontend-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_security_group" "backend_sg" {
  name   = "${var.project_name}-backend-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
  ingress {
    from_port       = 8082
    to_port         = 8082
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_security_group" "db_sg" {
  name   = "${var.project_name}-db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }
  ingress {
    from_port       = 3307
    to_port         = 3307
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# EC2
############################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "frontend_lt" {
  name_prefix            = "${var.project_name}-frontend-lt-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  iam_instance_profile {
    name = "LabInstanceProfile"
  }
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y && yum install -y docker
    systemctl start docker && systemctl enable docker
    usermod -aG docker ec2-user
  EOF
  )
}

resource "aws_launch_template" "backend_lt" {
  name_prefix            = "${var.project_name}-backend-lt-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  iam_instance_profile {
    name = "LabInstanceProfile"
  }
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y && yum install -y docker
    systemctl start docker && systemctl enable docker
    usermod -aG docker ec2-user
  EOF
  )
}

resource "aws_launch_template" "db_lt" {
  name_prefix            = "${var.project_name}-db-lt-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  iam_instance_profile {
    name = "LabInstanceProfile"
  }
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y && yum install -y docker
    systemctl start docker && systemctl enable docker
    until docker info > /dev/null 2>&1; do sleep 3; done
    docker run -d --name mysql-ventas --restart always \
      -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=ventas_db -p 3306:3306 mysql:8.0
    docker run -d --name mysql-despachos --restart always \
      -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=despachos_db -p 3307:3306 mysql:8.0
  EOF
  )
}

resource "aws_instance" "frontend" {
  subnet_id = aws_subnet.public.id
  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = "$Latest"
  }
  tags = { Name = "${var.project_name}-frontend" }
}

resource "aws_instance" "backend" {
  subnet_id = aws_subnet.public.id
  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }
  tags = { Name = "${var.project_name}-backend" }
}

resource "aws_instance" "db" {
  subnet_id = aws_subnet.private.id
  launch_template {
    id      = aws_launch_template.db_lt.id
    version = "$Latest"
  }
  tags = { Name = "${var.project_name}-database" }
}
