terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "deprem-yardim-cloud-infra"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.52.0"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

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

resource "aws_route_table" "route-table" {
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
    Name        = "route-table"
    Environment = var.environment
  }
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-a-gw.id
  }

  depends_on = [
    aws_vpc.vpc,
  ]
  tags = {
    Name        = "private-route-table"
    Environment = var.environment
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

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-subnet-a.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public-subnet-b.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "private-route-table-a" {
  subnet_id      = aws_subnet.private-subnet-a.id
  route_table_id = aws_route_table.private-route-table.id
}
resource "aws_route_table_association" "private-route-table-b" {
  subnet_id      = aws_subnet.private-subnet-b.id
  route_table_id = aws_route_table.private-route-table.id
}




resource "aws_ecr_repository" "base-ecr" {
  name                 = "base-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "ecr-policy" {
  repository = aws_ecr_repository.base-ecr.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 10 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
/*

module "iam" {
  source   = "./iam"
  username = "${var.name}-user"
}

module "opensearch" {
  source          = "./opensearch"
  name            = "${var.name}-os"
  region          = var.region
  vpc_id          = vpc.id
  public_subnets  = vpc.public_subnets
  private_subnets = vpc.private_subnets
  iam_user_arn    = iam.iam_user_arn
  iam_user_name   = iam.iam_user_name
}*/