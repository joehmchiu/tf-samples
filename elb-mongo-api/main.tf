terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "tf_mongo"
  }
}

resource "aws_subnet" "tf_mongo_subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf_mongo_subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "tf_mongo_ig"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "aws_route_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.tf_mongo_subnet.id
  route_table_id = aws_route_table.r.id
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "instance_sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.default.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "default" {
  template = file("${path.module}/scripts/temp.sh")
  vars = {
    hello = "Hello"
    world = "world"
  }
}

resource "aws_instance" "api" {
  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  ami = var.aws_amis[var.aws_region]

  key_name = var.key_name

  # Our Security group to allow 8600 and SSH access
  vpc_security_group_ids = [aws_security_group.default.id]
  subnet_id              = aws_subnet.tf_mongo_subnet.id
  # user_data              = file("userdata.sh")

  provisioner "file" {
    source      = "scripts/api.py"
    destination = "/tmp/api.py"
  }

  provisioner "file" {
    source      = "scripts/Dockerfile"
    destination = "/tmp/Dockerfile"
  }

  provisioner "file" {
    source      = "scripts/docker-mongo.sh"
    destination = "/tmp/docker-mongo.sh"
  }

  provisioner "file" {
    source      = "scripts/start.sh"
    destination = "/tmp/start.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /tmp",
      "DEBIAN_FRONTEND=noninteractive",
      "sh docker-mongo.sh ${var.user} ${var.token}",
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("/etc/keys/ssh-key01.key")}"
    host        = "${self.public_dns}"
  }

  user_data = data.template_file.default.rendered

  #Instance tags
  tags = {
    Name = "mongo-api"
  }
}

locals {
  tempfile = templatefile("${path.module}/scripts/ssh-config.tpl", {
    ip = "${aws_instance.api.public_ip}"
  })
}

resource "local_file" "ssh" {
  content = local.tempfile
  filename = "${path.module}/scripts/ssh-config.yml"

  provisioner "local-exec" {
    command = "ansible-playbook ${path.module}/scripts/ssh-config.yml"
  }
}

# Our elb security group to access
# the ELB over 8600
resource "aws_security_group" "elb" {
  name        = "elb_sg"
  description = "Used in the terraform"

  vpc_id = aws_vpc.default.id

  # HTTP access from anywhere
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ensure the VPC has an Internet gateway or this step will fail
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_elb" "api" {
  name = "mongo-api"

  # The same availability zone as our instance
  subnets = [aws_subnet.tf_mongo_subnet.id]

  security_groups = [aws_security_group.elb.id]

  listener {
    instance_port     = 8600
    instance_protocol = "http"
    lb_port           = 8600
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8600/api/v1/users/"
    interval            = 30
  }

  # The instance is registered automatically

  instances                   = [aws_instance.api.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

resource "aws_lb_cookie_stickiness_policy" "default" {
  name                     = "lbpolicy"
  load_balancer            = aws_elb.api.id
  lb_port                  = 8600
  cookie_expiration_period = 600
}

