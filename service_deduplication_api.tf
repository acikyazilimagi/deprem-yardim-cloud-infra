resource "aws_ec2_host" "deduplication-api" {
  instance_type     = "c5.large"
  availability_zone = "eu-central-1a"

}

resource "aws_lb" "deduplication-api-nlb" {
  name               = "deduplication-api-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = false

  tags = {
    Name = "deduplication"
  }
}

resource "aws_lb_target_group" "deduplication-api-tg" {
  name        = "deduplication-api-tg"
  port        = 19530
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = false
    path     = "/health"
    port     = 80
    protocol = "TCP"
  }
  tags = {
    Name        = "deduplication-api-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "deduplication-api-nlb-listener" {
  load_balancer_arn = aws_lb.deduplication-api-nlb.arn
  port              = "19530"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deduplication-api-tg.arn
  }
  depends_on = [
    aws_lb.deduplication-api-nlb
  ]
}

resource "aws_lb_target_group" "deduplication-api-tg" {
  name        = "deduplication-api-tg"
  port        = 9091
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = false
    path     = "/health"
    port     = 80
    protocol = "TCP"
  }
  tags = {
    Name        = "deduplication-api-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "deduplication-api-nlb-listener" {
  load_balancer_arn = aws_lb.deduplication-api-nlb.arn
  port              = "9091"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deduplication-api-tg.arn
  }
  depends_on = [
    aws_lb.deduplication-api-nlb
  ]
}
