provider "aws" {
  region = "us-east-1"
}

# Create a Default VPC (if it doesn't exist)
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# Retrieve all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

# Create a Security Group in the default VPC
resource "aws_security_group" "my_sg" {
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
    Name = "my_sg"
  }
}

# Find the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create an EC2 Instance in the default VPC and subnet
resource "aws_instance" "my_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.default.ids[0]  # Use the first subnet ID
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  associate_public_ip_address = true

  key_name = "my-key" # Replace with your key pair name

 user_data = <<-EOF
              #!/bin/bash
              # Update package list
              sudo apt-get update

              # Install Apache2
              sudo apt-get install -y apache2

              # Start and enable Apache2 service
              sudo systemctl start apache2
              sudo systemctl enable apache2

              # Install Docker
              curl -fsSL https://get.docker.com | sudo bash

              # Start and enable Docker service
              sudo systemctl start docker
              sudo systemctl enable docker
              EOF


  tags = {
    Name = "my_instance"
  }
}

# Output the Private and Public IPs of the Instance
output "private_ip" {
  value = aws_instance.my_instance.private_ip
}

output "public_ip" {
  value = aws_instance.my_instance.public_ip
}
