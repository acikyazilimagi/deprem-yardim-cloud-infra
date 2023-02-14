resource "aws_ec2_host" "deduplication-api" {
  instance_type     = "m5.large"
  availability_zone = "eu-central-1"
}

resource "aws_lb" "deduplication-api-nlb" {
  name               = "deduplication-api-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = ["sg-09d6376212dfa6ea1", "sg-06ff875226c82801f", "sg-04e80daf38921c9d4", "sg-0fc6eecb89164c95f"]
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "deduplication"
  }
}

resource "aws_lb_target_group" "deduplication-api-tg" {
  name        = "deduplication-api-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = true
    path     = "/health"
    port     = 80
    protocol = "HTTP"
  }
  tags = {
    Name        = "deduplication-api-tg"
    Environment = var.environment
  }
}


resource "aws_wafv2_web_acl_association" "deduplication-api-nlb" {
  resource_arn = aws_lb.deduplication-api-nlb.arn
  web_acl_arn  = aws_wafv2_web_acl.generic.arn
}

resource "aws_lb_listener" "deduplication-api-nlb-listener" {
  load_balancer_arn = aws_lb.deduplication-api-nlb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deduplication-api-tg.arn
  }
  depends_on = [
    aws_lb.deduplication-api-nlb
  ]
}
