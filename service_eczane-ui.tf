resource "aws_ecs_task_definition" "eczane-front-TD" {
  family                   = "eczane-front-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "eczane-front"
      cpu    = 2048
      memory = 4096
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/eczane-front"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_lb_target_group" "eczane-front-tg" {
  name        = "eczane-front-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = true
    path     = "/"
    port     = 80
    protocol = "HTTP"
  }
  tags = {
    Name        = "eczane-front-tg"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "eczane-front-service" {
  name            = "eczane-front-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.eczane-front-TD.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.eczane-front-TD,
    aws_lb_target_group.eczane-front-tg,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.eczane-front-tg.arn
    container_name   = "container-name"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_lb" "eczane-front-alb" {
  name               = "eczane-front"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-09d6376212dfa6ea1"] // Todo change
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "eczane-front-alb"
  }
}

resource "aws_wafv2_web_acl_association" "eczane-front-alb" {
  resource_arn = aws_lb.eczane-front-alb.arn
  web_acl_arn  = aws_wafv2_web_acl.generic.arn
}

resource "aws_lb_listener" "eczane-front-alb-listener" {
  load_balancer_arn = aws_lb.eczane-front-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eczane-front-tg.arn
  }
  depends_on = [
    aws_lb.eczane-front-alb
  ]
}

resource "aws_lb_listener_rule" "eczane-front-rule" {
  listener_arn = aws_lb_listener.eczane-front-alb-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eczane-front-tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
