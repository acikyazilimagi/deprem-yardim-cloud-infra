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
    description      = "HTTPS"
    from_port        = 3000
    to_port          = 3000
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

  ingress {
    description      = "HTTP"
    from_port        = 8080
    to_port          = 8080
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
resource "aws_lb" "backend-alb" {
  name               = "backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend-alb-sg.id]
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

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
    aws_lb.backend-alb
  ]
}

//------------- backend services ----------





//------------- backend go services ----------
//alb
resource "aws_lb" "backend-go-alb" {
  name               = "backend-go-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend-alb-sg.id]
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "backend-go-alb"
  }
}

//listener 
resource "aws_lb_listener" "backend-go-alb-listener" {
  load_balancer_arn = aws_lb.backend-go-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api-go-tg.arn
  }
  depends_on = [
    aws_lb.backend-go-alb
  ]
}

//------------- backend go services ----------


//------------- grafana services ----------
//alb
resource "aws_lb" "grafana-alb" {
  name               = "grafana-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend-alb-sg.id]
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "grafana-alb"
  }
}

//listener
resource "aws_lb_listener" "grafana-alb-listener" {
  load_balancer_arn = aws_lb.grafana-alb.arn
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana-tg.arn
  }
  depends_on = [
    aws_lb.grafana-alb
  ]
}

//------------- grafana services ----------


//------------- beniyiyim services ----------
//alb
resource "aws_lb" "beniyiyim-alb" {
  name               = "beniyiyim-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend-alb-sg.id]
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "beniyiyim-alb"
  }
}

//listener
resource "aws_lb_listener" "beniyiyim-alb-listener" {
  load_balancer_arn = aws_lb.beniyiyim-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.beniyiyim-tg.arn
  }
  depends_on = [
    aws_lb.beniyiyim-alb
  ]
}

//------------- beniyiyim services ----------



//------------- label-studio services ----------
//alb
resource "aws_lb" "label-studio-alb" {
  name               = "label-studio-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend-alb-sg.id]
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "label-studio-alb"
  }
}

//listener
resource "aws_lb_listener" "label-studio-alb-listener" {
  load_balancer_arn = aws_lb.label-studio-alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.label-studio-tg.arn
  }
  depends_on = [
    aws_lb.label-studio-alb
  ]
}

//------------- label-studio services ----------



//------------- prometheus services ----------
//alb
resource "aws_lb" "prometheus-alb" {
  name               = "prometheus-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend-alb-sg.id]
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "prometheus-alb"
  }
}

//listener
resource "aws_lb_listener" "prometheus-alb-listener" {
  load_balancer_arn = aws_lb.prometheus-alb.arn
  port              = "9090"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus-tg.arn
  }
  depends_on = [
    aws_lb.prometheus-alb
  ]
}

//------------- prometheus services ----------