terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.66.0"
    }
  }

  required_version = "~> 1.9.5"
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "main_vpc"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "gateway"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  count             = var.subnet_count.public
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "public_subnet_${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  count             = var.subnet_count.private
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "public_subnet_${count.index}"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "public" {
  count          = var.subnet_count.public
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table_association" "private" {
  count          = var.subnet_count.private
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}

resource "aws_security_group" "api_server_sg" {
  name        = "api_server_sg"
  description = "Security group for exposed EC2 web servers"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow all HTTP traffic"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all HTTPS traffic"
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # This may be a bad setting, but since we are using SSH certs
    # only for connecting, we should be all right,
    # All other forms of auth must be disabled in the NixOS
    # SSH module configuration itself.
    description = "Allow all SSH traffic"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "api_server_sg"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Security group for RDS clusters for EC2 instances to connect to"
  vpc_id      = aws_vpc.main_vpc.id

  # All other ingress traffic is deined.
  ingress {
    description     = "Allow PostgreSQL traffic from API server SG"
    from_port       = "5432"
    to_port         = "5432"
    protocol        = "tcp"
    security_groups = [aws_security_group.api_server_sg.id]
  }

  tags = {
    Name = "db_sg"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "db_subnet_group"
  description = "DB subnet group"
  subnet_ids  = [for subnet in aws_subnet.private_subnet : subnet.id]
}

resource "aws_db_instance" "database" {
  # AWS does not allow us to create a staging database alongside this in the
  # same RDS instance, so this will have to do.
  # This is the production database; other databases, like staging and
  # such, must be allocated at startup time or manually if they do not exist.
  # I would do multiple instances, but we're poor and are trying to
  # get AWS Free Tier benefits ;}
  db_name                = var.settings.database.db_name
  allocated_storage      = var.settings.database.allocated_storage
  engine                 = var.settings.database.engine
  engine_version         = var.settings.database.engine_version
  instance_class         = var.settings.database.instance_class
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = var.settings.database.skip_final_snapshot
}

resource "aws_key_pair" "ec2_access_kp" {
  key_name   = "ec2_access_kp"
  public_key = file("kp.pub")
}

data "aws_ami" "nixos_image" {
  owners      = ["427812963091"]
  most_recent = true

  filter {
    name   = "name"
    values = ["nixos/24.05*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "api_server" {
  count                  = var.settings.app.count
  ami                    = data.aws_ami.nixos_image.id
  instance_type          = var.settings.app.instance_type
  subnet_id              = aws_subnet.public_subnet[count.index].id
  key_name               = aws_key_pair.ec2_access_kp.key_name
  vpc_security_group_ids = [aws_security_group.api_server_sg.id]
  tags = {
    Name = "api_server_${count.index}"
  }
}

resource "aws_eip" "public_server_ip_addr" {
  count    = var.settings.app.count
  instance = aws_instance.api_server[count.index].id
  vpc      = true
  tags = {
    Name = "public_server_elastic_ip_${count.index}"
  }
}
