resource "aws_security_group" "backend-alb-sg" {
  name        = "alb-sg"
  description = "Allow HTTP/HTTPS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "backend-alb-sg"
  }
}
/////////////////////////


//------------- backend services ----------
//alb
rresource "aws_lb" "backend-alb" {
  name               = "backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend-alb-sg.id]
  subnets            = [aws_subnet.subnet-a.id, aws_subnet.subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "backend-alb"
  }
}

//listener 
resource "aws_lb_listener" "backend-alb-listener" {
  load_balancer_arn = aws_lb.backend-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api-tg.arn
  }
  depends_on = [
    aws_lb.api-alb
  ]
}

//------------- backend services ----------

