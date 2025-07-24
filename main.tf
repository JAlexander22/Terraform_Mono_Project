terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "Website_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MonoAppServer"
  }
}



# Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.Website_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2a"

  tags = {
    Name = "MonoAppServer"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.Website_vpc.id

  tags = {
    Name = "MonoAppServer"
  }
}




# Create a Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.Website_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "MonoAppServer"
  }
}


# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}



resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.Website_vpc.id

  # Allow SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP for security
  }

  # Allow HTTP Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #   # Allow Flask App Access This is a test
  # ingress {
  #   from_port   = 5000
  #   to_port     = 5000
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  tags = {
    Name = "MonoAppServer"
  }
}

resource "aws_instance" "app_server" {
  ami                    = "ami-091f18e98bc129c4e"
  instance_type          = "t2.micro"
  key_name               = "Mono-Terraform-Key"
  subnet_id              = aws_subnet.public_subnet.id # Attach to a public subnet
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "MonoAppServer"
  }
  user_data = file("app_script.sh")
  # user_data = <<-EOT
  #   #!/bin/bash
  #   sudo yum update -y
  #   sudo yum install -y curl wget git vim htop
  #   sudo yum install -y httpd
  #   sudo systemctl enable httpd
  #   sudo systemctl start httpd
  # EOT
}


output "app_server_IP_Address" {
  value = aws_instance.app_server[*].public_ip
}


