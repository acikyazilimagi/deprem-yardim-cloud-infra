variable "vpc_id" {
  default = "vpc-03db9b9432e6b8df8"
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "deduplication-sg" {
  name        = "deduplication"
  description = "SG for deduplication"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 19530
    to_port          = 19530
    protocol         = "tcp"
    cidr_blocks      = [data.aws_vpc.selected.cidr_block]
  }
  
    ingress {
    description      = "TLS from VPC"
    from_port        = 9091
    to_port          = 9091
    protocol         = "tcp"
    cidr_blocks      = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "deduplication_sg"
  }
}

resource "aws_instance" "deduplication" {
  ami                     = "ami-0d1ddd83282187d18"
  instance_type           = "c5.large"
  vpc_security_group_ids  = [aws_security_group.deduplication-sg.id]
  subnet_id               = "subnet-0d3f671f3e2e77332" 
  key_name                = "for-ec2"
  availability_zone       = "eu-central-1a"
}

resource "aws_lb" "deduplication-nlb" {
  name               = "deduplication-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = false

  tags = {
    Name = "deduplication"
  }
}

resource "aws_lb_target_group" "deduplication-tg-0" {
  name        = "deduplication-tg-0"
  port        = 19530
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.selected.id
  tags = {
    Name        = "deduplication-tg-0"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "deduplication-nlb-listener" {
  load_balancer_arn = aws_lb.deduplication-nlb.arn
  port              = "19530"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deduplication-tg-0.arn
  }
  depends_on = [
    aws_lb.deduplication-nlb
  ]
}

resource "aws_lb_target_group" "deduplication-tg-2" {
  name        = "deduplication-tg-2"
  port        = 9091
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.selected.id
  tags = {
    Name        = "deduplication-tg-2"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "deduplication-nlb-listener-2" {
  load_balancer_arn = aws_lb.deduplication-nlb.arn
  port              = "9091"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deduplication-tg-0.arn
  }
  depends_on = [
    aws_lb.deduplication-nlb
  ]
}

resource "aws_lb_target_group_attachment" "deduplication-19530" {
  target_group_arn = aws_lb_target_group.deduplication-tg-0.arn
  target_id        = aws_instance.deduplication.id
  port             = 19530
}

resource "aws_lb_target_group_attachment" "deduplication-9091" {
  target_group_arn = aws_lb_target_group.deduplication-tg-2.arn
  target_id        = aws_instance.deduplication.id
  port             = 9091
}

resource "aws_s3_bucket" "aya-deduplication" {
  bucket = "aya-deduplication"

  tags = {
    Name        = "deduplication"
    Environment = "production"
  }
}

resource "aws_s3_bucket_acl" "aya-deduplication" {
  bucket = aws_s3_bucket.aya-deduplication.id
  acl    = "private"
}

resource "aws_iam_user" "aya-deduplication-user" {
  name = "aya-deduplication-user"

  tags = {
    Name = "aya-deduplication"
  }
}

resource "aws_iam_access_key" "aya-deduplication" {
  user = aws_iam_user.aya-deduplication-user.name
}

resource "aws_iam_policy" "aya-deduplication-policy" {
  name = "aya-deduplication-policy"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
      "s3:*"
    ],
     "Resource": [
      "arn:aws:s3:::aya-deduplication",
      "arn:aws:s3:::aya-deduplication/*"
      ]
    }
  ]
})
}

resource "aws_iam_user_policy_attachment" "aya-deduplication-policy" {
  user       = aws_iam_user.aya-deduplication-user.name
  policy_arn = aws_iam_policy.aya-deduplication-policy.arn
}