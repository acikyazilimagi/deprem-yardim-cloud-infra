resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name        = "vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "gw3"
    Environment = var.environment
  }
}

resource "aws_eip" "nat-a-eip" {
  depends_on = [aws_internet_gateway.gw]
  vpc        = true

  tags = {
    Name = "gw NAT-A"
  }
}

resource "aws_eip" "nat-b-eip" {
  depends_on = [aws_internet_gateway.gw]
  vpc        = true

  tags = {
    Name = "gw NAT-B"
  }
}

resource "aws_nat_gateway" "nat-a-gw" {
  allocation_id = aws_eip.nat-a-eip.id
  subnet_id     = aws_subnet.private-subnet-a.id

  tags = {
    Name = "nat gateway A"
  }
}

resource "aws_nat_gateway" "nat-b-gw" {
  allocation_id = aws_eip.nat-b-eip.id
  subnet_id     = aws_subnet.private-subnet-b.id

  tags = {
    Name = "nat gateway B"
  }
}

resource "aws_subnet" "private-subnet-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.128/26"
  availability_zone = "${var.region}a"
  tags = {
    Name        = "private-subnet-a"
    Environment = var.environment
  }
}

resource "aws_subnet" "private-subnet-b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.192/26"
  availability_zone = "${var.region}b"
  tags = {
    Name        = "private-subnet-b"
    Environment = var.environment
  }
}

resource "aws_subnet" "public-subnet-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/26"
  availability_zone = "${var.region}a"

  tags = {
    Name        = "public-subnet-a"
    Environment = var.environment
  }
}

resource "aws_subnet" "public-subnet-b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.64/26"
  availability_zone = "${var.region}b"
  tags = {
    Name        = "public-subnet-b"
    Environment = var.environment
  }
}

resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.gw,
  ]

  tags = {
    Name        = "public-routes"
    Environment = var.environment
  }
}

resource "aws_route_table" "private-route-a" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-a-gw.id
  }

  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.gw,
  ]

  tags = {
    Name        = "private-route-a"
    Environment = var.environment
  }
}

resource "aws_route_table" "private-route-b" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-b-gw.id
  }

  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.gw,
  ]

  tags = {
    Name        = "private-route-b"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.public-subnet-a.id
  route_table_id = aws_route_table.public-route.id
}

resource "aws_route_table_association" "public-b" {
  subnet_id      = aws_subnet.public-subnet-b.id
  route_table_id = aws_route_table.public-route.id
}

resource "aws_route_table_association" "private-a" {
  subnet_id      = aws_subnet.private-subnet-a.id
  route_table_id = aws_route_table.private-route-a.id
}
resource "aws_route_table_association" "private-b" {
  subnet_id      = aws_subnet.private-subnet-b.id
  route_table_id = aws_route_table.private-route-b.id
}
