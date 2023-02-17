resource "aws_ecs_task_definition" "service-dedup-api-TD" {
  family                   = "service-dedup-api-TD"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name   = "container-name"
      image  = "service-dedup-api"
      cpu    = 1024
      memory = 2048
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/service-dedup-api"
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

resource "aws_lb_target_group" "service-dedup-api-tg" {
  name        = "service-dedup-api-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled  = true
    path     = "/health-check"
    port     = 80
    protocol = "HTTP"
  }
  tags = {
    Name        = "service-dedup-api-tg"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "service-dedup-api-service" {
  name            = "service-dedup-api-service"
  cluster         = aws_ecs_cluster.base-cluster.id
  task_definition = aws_ecs_task_definition.service-dedup-api-TD.id
  desired_count   = 1
  depends_on = [
    aws_ecs_cluster.base-cluster,
    aws_ecs_task_definition.service-dedup-api-TD,
    aws_lb_target_group.service-dedup-api-tg,
  ]
  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id]
    security_groups  = [aws_security_group.service-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service-dedup-api-tg.arn
    container_name   = "container-name"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}


resource "aws_lb_listener_rule" "service-dedup-api-rule" {
  listener_arn = aws_lb_listener.service-dedup-api-alb-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service-dedup-api-tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_lb" "service-dedup-api-alb" {
  name               = "service-dedup-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-09d6376212dfa6ea1"] // Todo change
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "service-dedup-api-alb"
  }
}

resource "aws_wafv2_web_acl_association" "service-dedup-api-alb" {
  resource_arn = aws_lb.service-dedup-api-alb.arn
  web_acl_arn  = aws_wafv2_web_acl.generic.arn
}

resource "aws_lb_listener" "service-dedup-api-alb-listener" {
  load_balancer_arn = aws_lb.service-dedup-api-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service-dedup-api-tg.arn
  }
  depends_on = [
    aws_lb.service-dedup-api-alb
  ]
}
