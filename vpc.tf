# VPC

resource "aws_vpc" "first_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "${var.env}_first_vpc"
  }
}

# Public Subnets

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.first_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "${var.env}_pub_sub_1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.first_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "${var.env}_pub_sub_2"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id     = aws_vpc.first_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2c"

  tags = {
    Name = "${var.env}_pub_sub_3"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.first_vpc.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "${var.env}_private_sub_1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.first_vpc.id
  cidr_block = "10.0.12.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "${var.env}_private_sub_2"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id     = aws_vpc.first_vpc.id
  cidr_block = "10.0.13.0/24"
  availability_zone = "us-west-2c"

  tags = {
    Name = "${var.env}_private_sub_3"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.first_vpc.id

  tags = {
    Name = "${var.env}_internet_gateway"
  }
}

# Elastic IP

resource "aws_eip" "nat_gateway_eip" {
  vpc = true
  tags = {
    Name = "${var.env}_eip"
  }
}

# NAT Gateway

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  depends_on    = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = "${var.env}_nat_gateway"
  }
}

# Public Route Table

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.first_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "${var.env}_public_rt"
  }
}

# Public Route Table Association

resource "aws_route_table_association" "pub_sub_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "pub_sub_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "pub_sub_3" {
  subnet_id      = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.public_route_table.id
}

# Private Route Table

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.first_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "${var.env}_private_rt"
  }
}

# Private Route Table Association

resource "aws_route_table_association" "private_sub_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_sub_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_sub_3" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private_route_table.id
}

# EC2

resource "aws_instance" "main" {
  count                  = 1
  ami                    = data.aws_ami.amazon_linux_2.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = aws_subnet.public_subnet_1.id
  key_name               = var.key_name
  tags = {
    Name = "${var.env}-instance"
  }
}

# Security Group for EC2

resource "aws_security_group" "main" {
  name        = "${var.env}-instance-sg"
  description = "This is a sg for my EC2"
  vpc_id      = aws_vpc.first_vpc.id
}

resource "aws_security_group_rule" "ingress_rule" {
  count             = length(var.ingress_ports)
  type              = "ingress"
  from_port         = element(var.ingress_ports, count.index)
  to_port           = element(var.ingress_ports, count.index)
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "egress_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # All protocols
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}