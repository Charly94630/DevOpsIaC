provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "default vpc"
  }
}

data "aws_availability_zones" "available_zones" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "default subnet"
  }
}

resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 8080 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description = "http proxy access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins server security group"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "ec2_jenkins" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "ec2_keypair"

  tags = {
    Name = "Jenkins server"
  }
}

resource "null_resource" "name" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/ec2_key.pem")
    host        = aws_instance.ec2_jenkins.public_ip
  }

  provisioner "file" {
    source      = "~/installjenkins.sh"
    destination = "/tmp/installjenkins.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/installjenkins.sh",
      "sh /tmp/installjenkins.sh"
    ]
  }

  depends_on = [aws_instance.ec2_jenkins]
}

output "website_url" {
  value = join("", ["http://", aws_instance.ec2_jenkins.public_dns, ":", "8080"])
}
