terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = "eu-west-2"
  access_key = "nah bruh not today"
  secret_key = "not today sir"
}

resource "aws_vpc" "dev-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    name : "dev"
  }
}

resource "aws_subnet" "dev-subnet" {
  vpc_id                  = aws_vpc.dev-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2a"

  tags = {
    name : "dev_public_subnet"
  }
}

resource "aws_internet_gateway" "dev_vpc_igw" {
  vpc_id = aws_vpc.dev-vpc.id

  tags = {
    name : "dev_igw"
  }
}

resource "aws_route_table" "dev_public_rt" {
  vpc_id = aws_vpc.dev-vpc.id

  tags = {
    name : "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.dev_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev_vpc_igw.id
}

resource "aws_route_table_association" "dev_public_asoc" {
  subnet_id      = aws_subnet.dev-subnet.id
  route_table_id = aws_route_table.dev_public_rt.id
}

resource "aws_security_group" "dev_sg" {
  name        = "dev_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev_sg"
  }
}

resource "aws_key_pair" "dev_key" {
  key_name   = "devkey"
  public_key = file("~/.ssh/aws_devkey.pub")
}

resource "aws_instance" "dev-node" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.server_ami.id

  key_name               = aws_key_pair.dev_key.id
  vpc_security_group_ids = [aws_security_group.dev_sg.id]
  subnet_id              = aws_subnet.dev-subnet.id

  user_data = file("userdata.tpl")


  tags = {
    name = "dev-node"
  }
}